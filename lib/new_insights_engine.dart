import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'health_data_models.dart';
import 'data_source_manager.dart';
import 'wellness_scoring_engine.dart';
import 'wellness_predictor.dart';

enum Grade { red, amber, green }

enum DateRange { daily, weekly, monthly, overall }

class NewInsightsEngine {
  final Box _metricsBox;
  final DataSourceManager _dataSourceManager;
  final WellnessScoringEngine _scoringEngine;
  final WellnessPredictor _predictor;
  bool _isPredictorInitialized = false;

  NewInsightsEngine(this._metricsBox)
    : _dataSourceManager = DataSourceManager(),
      _scoringEngine = WellnessScoringEngine(),
      _predictor = WellnessPredictor();

  Future<void> initialize() async {
    await _dataSourceManager.initialize();
    await _ensurePredictor();
  }

  Future<void> _ensurePredictor() async {
    if (!_isPredictorInitialized) {
      try {
        await _predictor.loadModel();
        _isPredictorInitialized = true;
      } catch (e) {
        print('Error initializing predictor: $e');
        rethrow;
      }
    }
  }

  Future<void> dispose() async {
    if (_isPredictorInitialized) {
      _predictor.close();
      _isPredictorInitialized = false;
    }
  }

  // Get wellness score using new unified system
  Future<double> getWellnessScore(String userId, DateRange range) async {
    if (userId.isEmpty) {
      print('Error: Empty user ID provided');
      return 0.0;
    }

    try {
      final dateRange = _getDateTimeRange(range);
      final allData = await _dataSourceManager.fetchAllData(dateRange);

      if (allData.isEmpty) {
        // Fallback to manual entry data from Hive
        return await _getManualEntryScore(userId, range);
      }

      // Use the best quality data available
      final bestData = _getBestQualityData(allData);
      return _scoringEngine.calculateOverallWellness(bestData);
    } catch (e) {
      print('Error calculating wellness score: $e');
      return await _getManualEntryScore(userId, range);
    }
  }

  // Get category grades using new system
  Future<Map<String, Grade>> getCategoryGrades(
    String userId,
    DateRange range,
  ) async {
    if (userId.isEmpty) {
      print('Error: Empty user ID provided');
      return {};
    }

    try {
      final dateRange = _getDateTimeRange(range);
      final allData = await _dataSourceManager.fetchAllData(dateRange);

      if (allData.isEmpty) {
        return await _getManualEntryGrades(userId, range);
      }

      final bestData = _getBestQualityData(allData);
      return _calculateCategoryGradesWithDateRange(bestData, range);
    } catch (e) {
      print('Error calculating category grades: $e');
      return await _getManualEntryGrades(userId, range);
    }
  }

  // Get data quality information
  DataQuality getCurrentDataQuality() {
    return _dataSourceManager.getCurrentDataQuality();
  }

  // Get connected data sources
  List<DataSource> getConnectedSources() {
    return _dataSourceManager.connectedSources;
  }

  // Connect to a data source
  Future<bool> connectDataSource(DataSource source) async {
    switch (source) {
      case DataSource.appleHealth:
        return await _dataSourceManager.connectAppleHealth();
      case DataSource.googleFit:
        return await _dataSourceManager.connectGoogleFit();
      case DataSource.ouraRing:
        // TODO: Get API key from user
        return await _dataSourceManager.connectOuraRing('placeholder_api_key');
      default:
        return false;
    }
  }

  // Disconnect from a data source
  Future<void> disconnectDataSource(DataSource source) async {
    await _dataSourceManager.disconnectDataSource(source);
  }

  // Private helper methods

  DateTimeRange _getDateTimeRange(DateRange range) {
    switch (range) {
      case DateRange.daily:
        return DateTimeRange.today();
      case DateRange.weekly:
        return DateTimeRange.thisWeek();
      case DateRange.monthly:
        return DateTimeRange.thisMonth();
      case DateRange.overall:
        // Overall = last 30 days for comprehensive view
        final now = DateTime.now();
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        return DateTimeRange(start: thirtyDaysAgo, end: now);
    }
  }

  UnifiedHealthData _getBestQualityData(List<UnifiedHealthData> allData) {
    if (allData.isEmpty) return UnifiedHealthData.empty();

    // Sort by data quality and return the best
    allData.sort((a, b) => b.quality.index.compareTo(a.quality.index));
    return allData.first;
  }

  Map<String, Grade> _calculateCategoryGrades(UnifiedHealthData data) {
    final grades = <String, Grade>{};

    // Calculate sleep health score (25% weight)
    final sleepHealthScore = _calculateSleepHealthScore(data);
    grades['sleep_health'] = _scoreToGrade(sleepHealthScore);

    // Calculate cardiovascular score (15% weight)
    final cardiovascularScore = _calculateCardiovascularScore(data);
    grades['cardiovascular'] = _scoreToGrade(cardiovascularScore);

    // Calculate physical activity score (20% weight)
    final physicalActivityScore = _calculatePhysicalActivityScore(data);
    grades['physical_activity'] = _scoreToGrade(physicalActivityScore);

    // Calculate consistency habits score (10% weight)
    final consistencyHabitsScore = _calculateConsistencyHabitsScore(data);
    grades['consistency_habits'] = _scoreToGrade(consistencyHabitsScore);

    // Calculate recovery stress score (15% weight)
    final recoveryStressScore = _calculateRecoveryStressScore(data);
    grades['recovery_stress'] = _scoreToGrade(recoveryStressScore);

    // Calculate social wellness score (10% weight)
    final socialWellnessScore = _calculateSocialWellnessScore(data);
    grades['social_wellness'] = _scoreToGrade(socialWellnessScore);

    // Calculate nutrition hydration score (3% weight)
    final nutritionHydrationScore = _calculateNutritionHydrationScore(data);
    grades['nutrition_hydration'] = _scoreToGrade(nutritionHydrationScore);

    // Calculate mental wellness score (2% weight)
    final mentalWellnessScore = _calculateMentalWellnessScore(data);
    grades['mental_wellness'] = _scoreToGrade(mentalWellnessScore);

    return grades;
  }

  // NEW: Date range-aware category grading
  Map<String, Grade> _calculateCategoryGradesWithDateRange(
    UnifiedHealthData data,
    DateRange range,
  ) {
    final grades = <String, Grade>{};

    // Categories that work well for daily view
    if (range == DateRange.daily ||
        range == DateRange.weekly ||
        range == DateRange.monthly ||
        range == DateRange.overall) {
      // Cardiovascular - Daily snapshots work fine
      final cardiovascularScore = _calculateCardiovascularScore(data);
      grades['cardiovascular'] = _scoreToGrade(cardiovascularScore);

      // Physical Activity - Daily metrics are meaningful
      final physicalActivityScore = _calculatePhysicalActivityScore(data);
      grades['physical_activity'] = _scoreToGrade(physicalActivityScore);

      // Nutrition & Hydration - Daily intake tracking
      final nutritionHydrationScore = _calculateNutritionHydrationScore(data);
      grades['nutrition_hydration'] = _scoreToGrade(nutritionHydrationScore);

      // Mental Wellness - Daily mindfulness activities
      final mentalWellnessScore = _calculateMentalWellnessScore(data);
      grades['mental_wellness'] = _scoreToGrade(mentalWellnessScore);
    }

    // Categories that need multi-day data (weekly/monthly/overall only)
    if (range == DateRange.weekly ||
        range == DateRange.monthly ||
        range == DateRange.overall) {
      // Sleep Health - Patterns emerge over multiple days
      final sleepHealthScore = _calculateSleepHealthScore(data);
      grades['sleep_health'] = _scoreToGrade(sleepHealthScore);

      // Consistency & Habits - Weekly consistency is meaningful
      final consistencyHabitsScore = _calculateConsistencyHabitsScore(data);
      grades['consistency_habits'] = _scoreToGrade(consistencyHabitsScore);

      // Recovery & Stress - Recovery patterns need multiple days
      final recoveryStressScore = _calculateRecoveryStressScore(data);
      grades['recovery_stress'] = _scoreToGrade(recoveryStressScore);

      // Social Wellness - Social patterns emerge over time
      final socialWellnessScore = _calculateSocialWellnessScore(data);
      grades['social_wellness'] = _scoreToGrade(socialWellnessScore);
    }

    // For daily view, evaluate multi-day categories based on weekly goal progress
    if (range == DateRange.daily) {
      // Sleep Health - Check if today's sleep is on track for weekly average
      final sleepHealthScore = _calculateDailySleepHealthProgress(data);
      grades['sleep_health'] = _scoreToGrade(sleepHealthScore);

      // Consistency & Habits - Check if today's activity is consistent with weekly pattern
      final consistencyHabitsScore = _calculateDailyConsistencyProgress(data);
      grades['consistency_habits'] = _scoreToGrade(consistencyHabitsScore);

      // Recovery & Stress - Check if today's recovery indicators are good
      final recoveryStressScore = _calculateDailyRecoveryProgress(data);
      grades['recovery_stress'] = _scoreToGrade(recoveryStressScore);

      // Social Wellness - Check if today's social activity is on track
      final socialWellnessScore = _calculateDailySocialProgress(data);
      grades['social_wellness'] = _scoreToGrade(socialWellnessScore);
    }

    return grades;
  }

  // NEW: Daily progress evaluation methods for multi-day categories

  // Evaluate if today's sleep is on track for weekly goals
  double _calculateDailySleepHealthProgress(UnifiedHealthData data) {
    double score = 0;

    // Sleep duration progress (40% of daily progress)
    if (data.sleep?.totalSleep != null) {
      double hours =
          data.sleep!.totalSleep.inHours +
          (data.sleep!.totalSleep.inMinutes % 60) / 60.0;
      // Check if it's close to the 7-9 hour target
      if (hours >= 6.5 && hours <= 9.5) {
        score += 1.0 * 0.40; // On track
      } else if (hours >= 6.0 && hours <= 10.0) {
        score += 0.7 * 0.40; // Close to target
      } else {
        score += 0.3 * 0.40; // Off track
      }
    } else {
      score += 0.5 * 0.40; // No data
    }

    // Sleep efficiency progress (30% of daily progress)
    if (data.sleep?.sleepEfficiency != null) {
      if (data.sleep!.sleepEfficiency >= 0.85) {
        score += 1.0 * 0.30; // Good efficiency
      } else if (data.sleep!.sleepEfficiency >= 0.75) {
        score += 0.7 * 0.30; // Acceptable efficiency
      } else {
        score += 0.3 * 0.30; // Poor efficiency
      }
    } else {
      score += 0.5 * 0.30; // No data
    }

    // Sleep quality progress (30% of daily progress)
    double qualityScore = _calculateSleepQualityScore(data.sleep);
    score += qualityScore * 0.30;

    return score;
  }

  // Evaluate if today's activity is consistent with weekly patterns
  double _calculateDailyConsistencyProgress(UnifiedHealthData data) {
    double score = 0;

    // Physical activity consistency (50% of daily progress)
    // Check if today's activity level is consistent with weekly average
    if (data.steps > 0) {
      // If steps are in a good range, consider it consistent
      if (data.steps >= 6000) {
        score += 1.0 * 0.50; // Good daily activity
      } else if (data.steps >= 4000) {
        score += 0.7 * 0.50; // Moderate daily activity
      } else {
        score += 0.3 * 0.50; // Low daily activity
      }
    } else {
      score += 0.5 * 0.50; // No data
    }

    // Exercise consistency (50% of daily progress)
    if (data.exerciseSessions > 0) {
      score += 1.0 * 0.50; // Exercised today
    } else {
      // Check if it's a rest day (every 3-4 days is acceptable)
      score += 0.6 * 0.50; // Rest day is acceptable
    }

    return score;
  }

  // Evaluate if today's recovery indicators are good
  double _calculateDailyRecoveryProgress(UnifiedHealthData data) {
    double score = 0;

    // Sleep quality as recovery indicator (60% of daily progress)
    double sleepQualityScore = _calculateSleepQualityScore(data.sleep);
    score += sleepQualityScore * 0.60;

    // Activity level vs recovery (40% of daily progress)
    // If they had good activity yesterday, today should show recovery
    if (data.steps < 3000) {
      score += 1.0 * 0.40; // Good recovery (low activity)
    } else if (data.steps < 6000) {
      score += 0.7 * 0.40; // Moderate recovery
    } else {
      score += 0.4 * 0.40; // High activity (might need recovery)
    }

    return score;
  }

  // Evaluate if today's social activity is on track
  double _calculateDailySocialProgress(UnifiedHealthData data) {
    double score = 0;

    // Social interaction score (70% of daily progress)
    score += data.socialInteractionScore * 0.70;

    // Support network score (30% of daily progress)
    score += data.supportNetworkScore * 0.30;

    return score;
  }

  double _calculatePhysiologicalScore(UnifiedHealthData data) {
    double score = 0;

    // HRV Score (30% of physiological)
    if (data.hrv != null) {
      double hrvScore = _calculateHRVScore(data.hrv!, data.age);
      score += hrvScore * 0.30;
    }

    // Sleep Quality Score (40% of physiological)
    double sleepScore = _calculateSleepScore(data.sleep);
    score += sleepScore * 0.40;

    // Heart Health Score (20% of physiological)
    double heartScore = _calculateHeartScore(data);
    score += heartScore * 0.20;

    // Recovery Score (10% of physiological)
    if (data.recoveryScore != null) {
      score += (data.recoveryScore! / 100.0) * 0.10;
    }

    return score;
  }

  double _calculateBehavioralScore(UnifiedHealthData data) {
    double score = 0;

    // Physical activity (50% of behavioral)
    double activityScore = _calculateActivityScore(data);
    score += activityScore * 0.50;

    // Consistency (30% of behavioral)
    score += data.weeklyActivityConsistency * 0.30;

    // Movement patterns (20% of behavioral)
    double movementScore = _calculateMovementScore(data);
    score += movementScore * 0.20;

    return score;
  }

  double _calculateLifestyleScore(UnifiedHealthData data) {
    double score = 0;

    // Sleep patterns (60% of lifestyle)
    double sleepPatternScore = _calculateSleepPatternScore(data.sleep);
    score += sleepPatternScore * 0.60;

    // Recovery quality (40% of lifestyle)
    double recoveryScore = _calculateRecoveryScore(data);
    score += recoveryScore * 0.40;

    return score;
  }

  double _calculateSocialScore(UnifiedHealthData data) {
    return (data.socialInteractionScore + data.supportNetworkScore) / 2.0;
  }

  double _calculateHRVScore(double hrv, int age) {
    // Age-adjusted HRV scoring
    Map<int, Map<String, double>> ageHRVRanges = {
      20: {'min': 40, 'max': 80, 'optimal': 60},
      30: {'min': 35, 'max': 70, 'optimal': 55},
      40: {'min': 30, 'max': 60, 'optimal': 50},
      50: {'min': 25, 'max': 50, 'optimal': 45},
      60: {'min': 20, 'max': 45, 'optimal': 40},
    };

    var range = ageHRVRanges[age] ?? ageHRVRanges[30]!;
    double normalizedScore =
        (hrv - range['min']!) / (range['max']! - range['min']!);
    return normalizedScore.clamp(0.0, 1.0);
  }

  double _calculateSleepScore(SleepData? sleep) {
    if (sleep == null) return 0.5;

    double score = 0;
    score += sleep.sleepEfficiency * 0.30;

    if (sleep.deepSleepPercentage != null) {
      double deepSleepScore = (sleep.deepSleepPercentage! / 25.0).clamp(
        0.0,
        1.0,
      );
      score += deepSleepScore * 0.40;
    }

    if (sleep.remSleepPercentage != null) {
      double remScore = (sleep.remSleepPercentage! / 25.0).clamp(0.0, 1.0);
      score += remScore * 0.20;
    }

    double durationScore = (sleep.totalSleep.inHours / 8.0).clamp(0.0, 1.0);
    score += durationScore * 0.10;

    return score;
  }

  double _calculateHeartScore(UnifiedHealthData data) {
    if (data.heartRate == null) return 0.5;

    // Optimal RHR is 60-70 bpm
    double rhr = data.heartRate!;
    if (rhr >= 60 && rhr <= 70) return 1.0;
    if (rhr < 60) return 0.8;
    if (rhr <= 80) return 0.6;
    if (rhr <= 90) return 0.4;
    return 0.2;
  }

  double _calculateActivityScore(UnifiedHealthData data) {
    double score = 0;
    double stepsScore = (data.steps / 10000.0).clamp(0.0, 1.0);
    score += stepsScore * 0.40;

    double activeScore = (data.activeMinutes / 150.0).clamp(0.0, 1.0);
    score += activeScore * 0.40;

    double exerciseScore = (data.exerciseSessions / 3.0).clamp(0.0, 1.0);
    score += exerciseScore * 0.20;

    return score;
  }

  double _calculateMovementScore(UnifiedHealthData data) {
    double sedentaryTime = data.sedentaryMinutes / 480.0;
    double movementQuality = 1.0 - sedentaryTime.clamp(0.0, 1.0);
    return movementQuality;
  }

  double _calculateSleepPatternScore(SleepData? sleep) {
    if (sleep == null) return 0.5;

    double score = 0;
    score += sleep.scheduleConsistency * 0.40;
    score += sleep.environmentScore * 0.30;
    score += sleep.preSleepRoutineScore * 0.30;

    return score;
  }

  double _calculateRecoveryScore(UnifiedHealthData data) {
    double score = 0;

    if (data.recoveryScore != null) {
      score += (data.recoveryScore! / 100.0) * 0.60;
    }

    score += data.restDayAdherence * 0.40;

    return score;
  }

  // NEW: 8-category scoring methods

  // Sleep Health scoring (25% weight)
  double _calculateSleepHealthScore(UnifiedHealthData data) {
    double score = 0;

    // Sleep duration (40% of sleep health)
    if (data.sleep?.totalSleep != null) {
      double durationScore = _calculateSleepDurationScore(
        data.sleep!.totalSleep,
      );
      score += durationScore * 0.40;
    } else {
      score += 0.6 * 0.40; // Default for missing data
    }

    // Sleep efficiency (30% of sleep health)
    if (data.sleep?.sleepEfficiency != null) {
      double efficiencyScore = _calculateSleepEfficiencyScore(
        data.sleep!.sleepEfficiency,
      );
      score += efficiencyScore * 0.30;
    } else {
      score += 0.7 * 0.30; // Default for missing data
    }

    // Sleep quality (20% of sleep health) - Deep/REM sleep
    double qualityScore = _calculateSleepQualityScore(data.sleep);
    score += qualityScore * 0.20;

    // Sleep consistency (10% of sleep health) - Bedtime/waketime consistency
    double consistencyScore = _calculateSleepConsistencyScore(data.sleep);
    score += consistencyScore * 0.10;

    return score;
  }

  // Cardiovascular scoring (15% weight)
  double _calculateCardiovascularScore(UnifiedHealthData data) {
    double score = 0;

    // HRV Score (40% of cardiovascular)
    if (data.hrv != null) {
      double hrvScore = _calculateHRVScore(data.hrv!, data.age);
      score += hrvScore * 0.40;
    } else {
      score += 0.7 * 0.40; // Default for missing HRV
    }

    // Resting Heart Rate (40% of cardiovascular)
    if (data.heartRate != null) {
      double rhrScore = _calculateRHRScore(data.heartRate!);
      score += rhrScore * 0.40;
    } else {
      score += 0.7 * 0.40; // Default for missing RHR
    }

    // Exercise Heart Rate (20% of cardiovascular)
    double exerciseHRScore = _calculateExerciseHRScore(data.exercises);
    score += exerciseHRScore * 0.20;

    return score;
  }

  // Physical Activity scoring (20% weight)
  double _calculatePhysicalActivityScore(UnifiedHealthData data) {
    double score = 0;

    // Steps (40% of physical activity)
    if (data.steps > 0) {
      double stepsScore = _calculateStepsScore(data.steps);
      score += stepsScore * 0.40;
    } else {
      score += 0.5 * 0.40; // Default for missing steps
    }

    // Active minutes (35% of physical activity)
    if (data.activeMinutes > 0) {
      double activeScore = _calculateActiveMinutesScore(data.activeMinutes);
      score += activeScore * 0.35;
    } else {
      score += 0.5 * 0.35; // Default for missing active minutes
    }

    // Exercise sessions (25% of physical activity)
    if (data.exerciseSessions > 0) {
      double exerciseScore = _calculateExerciseSessionsScore(
        data.exerciseSessions,
      );
      score += exerciseScore * 0.25;
    } else {
      score += 0.3 * 0.25; // Default for missing exercise sessions
    }

    return score;
  }

  // Consistency & Habits scoring (10% weight)
  double _calculateConsistencyHabitsScore(UnifiedHealthData data) {
    double score = 0;

    // Weekly consistency (60% of consistency)
    double consistencyScore = _calculateConsistencyScore(data);
    score += consistencyScore * 0.60;

    // Movement patterns (40% of consistency)
    double movementScore = _calculateMovementScore(data);
    score += movementScore * 0.40;

    return score;
  }

  // Recovery & Stress scoring (15% weight)
  double _calculateRecoveryStressScore(UnifiedHealthData data) {
    double score = 0;

    // Recovery quality (70% of recovery)
    double recoveryScore = _calculateRecoveryScore(data);
    score += recoveryScore * 0.70;

    // Stress management (30% of recovery) - Based on HRV variability, sleep quality
    double stressScore = _calculateStressManagementScore(data);
    score += stressScore * 0.30;

    return score;
  }

  // Social Wellness scoring (10% weight)
  double _calculateSocialWellnessScore(UnifiedHealthData data) {
    double score = 0;

    // Social interactions (50% of social)
    double interactionScore = _calculateInteractionScore(data);
    score += interactionScore * 0.50;

    // Support network (50% of social)
    double supportScore = _calculateSupportScore(data);
    score += supportScore * 0.50;

    return score;
  }

  // Nutrition & Hydration scoring (3% weight)
  double _calculateNutritionHydrationScore(UnifiedHealthData data) {
    double score = 0;

    // Hydration (70% of nutrition) - Based on activity level and climate
    double hydrationScore = _calculateHydrationScore(data);
    score += hydrationScore * 0.70;

    // Nutrition quality (30% of nutrition) - Placeholder for future integration
    double nutritionScore = _calculateNutritionQualityScore(data);
    score += nutritionScore * 0.30;

    return score;
  }

  // Mental Wellness scoring (2% weight)
  double _calculateMentalWellnessScore(UnifiedHealthData data) {
    double score = 0;

    // Mindfulness activities (60% of mental wellness)
    double mindfulnessScore = _calculateMindfulnessScore(data);
    score += mindfulnessScore * 0.60;

    // Mental health indicators (40% of mental wellness) - Based on sleep, stress, social
    double mentalHealthScore = _calculateMentalHealthIndicatorsScore(data);
    score += mentalHealthScore * 0.40;

    return score;
  }

  // Helper methods for the new scoring system

  double _calculateSleepDurationScore(Duration sleepDuration) {
    double hours =
        sleepDuration.inHours + (sleepDuration.inMinutes % 60) / 60.0;
    if (hours >= 7.0 && hours <= 9.0) return 1.0; // Optimal
    if (hours >= 6.5 && hours < 7.0) return 0.9; // Very good
    if (hours >= 6.0 && hours < 6.5) return 0.8; // Good
    if (hours >= 5.5 && hours < 6.0) return 0.6; // Moderate
    if (hours >= 5.0 && hours < 5.5) return 0.4; // Poor
    if (hours >= 9.0 && hours <= 10.0) return 0.8; // Too much sleep
    if (hours > 10.0) return 0.3; // Excessive sleep
    return 0.2; // Very poor (<5 hours)
  }

  double _calculateSleepEfficiencyScore(double efficiency) {
    if (efficiency >= 0.95) return 1.0; // Excellent
    if (efficiency >= 0.90) return 0.9; // Very good
    if (efficiency >= 0.85) return 0.8; // Good
    if (efficiency >= 0.80) return 0.7; // Moderate
    if (efficiency >= 0.75) return 0.6; // Fair
    if (efficiency >= 0.70) return 0.4; // Poor
    return 0.2; // Very poor
  }

  double _calculateSleepQualityScore(SleepData? sleep) {
    if (sleep == null) return 0.7; // Default for missing data

    double score = 0;

    // Deep sleep percentage (60% of quality)
    if (sleep.deepSleepPercentage != null) {
      if (sleep.deepSleepPercentage! >= 20)
        score += 1.0 * 0.60; // Excellent
      else if (sleep.deepSleepPercentage! >= 15)
        score += 0.8 * 0.60; // Good
      else if (sleep.deepSleepPercentage! >= 10)
        score += 0.6 * 0.60; // Moderate
      else
        score += 0.4 * 0.60; // Poor
    } else {
      score += 0.7 * 0.60; // Default for missing data
    }

    // REM sleep percentage (40% of quality)
    if (sleep.remSleepPercentage != null) {
      if (sleep.remSleepPercentage! >= 25)
        score += 1.0 * 0.40; // Excellent
      else if (sleep.remSleepPercentage! >= 20)
        score += 0.8 * 0.40; // Good
      else if (sleep.remSleepPercentage! >= 15)
        score += 0.6 * 0.40; // Moderate
      else
        score += 0.4 * 0.40; // Poor
    } else {
      score += 0.7 * 0.40; // Default for missing data
    }

    return score;
  }

  double _calculateSleepConsistencyScore(SleepData? sleep) {
    if (sleep == null) return 0.6; // Default for missing data

    // Schedule consistency (70% of consistency)
    double scheduleScore = sleep.scheduleConsistency * 0.70;

    // Sleep latency (30% of consistency) - shorter is better
    double latencyScore = 0;
    if (sleep.sleepLatency.inMinutes <= 10)
      latencyScore = 1.0;
    else if (sleep.sleepLatency.inMinutes <= 20)
      latencyScore = 0.8;
    else if (sleep.sleepLatency.inMinutes <= 30)
      latencyScore = 0.6;
    else
      latencyScore = 0.4;

    return scheduleScore + (latencyScore * 0.30);
  }

  double _calculateRHRScore(double rhr) {
    if (rhr >= 50 && rhr <= 70) return 1.0; // Excellent (includes athletes)
    if (rhr >= 45 && rhr < 50) return 0.9; // Very good (athlete level)
    if (rhr >= 70 && rhr <= 80) return 0.8; // Good
    if (rhr >= 40 && rhr < 45) return 0.8; // Good (elite athlete)
    if (rhr >= 80 && rhr <= 90) return 0.6; // Moderate
    if (rhr >= 90 && rhr <= 100) return 0.4; // Elevated
    if (rhr > 100) return 0.2; // High stress indicator
    return 0.3; // Very low (could be concerning)
  }

  double _calculateExerciseHRScore(List<ExerciseSession>? exerciseSessions) {
    if (exerciseSessions == null || exerciseSessions.isEmpty)
      return 0.5; // Default

    // Calculate average exercise heart rate
    double totalHR = 0;
    int count = 0;

    for (var session in exerciseSessions) {
      if (session.averageHeartRate != null) {
        totalHR += session.averageHeartRate!;
        count++;
      }
    }

    if (count == 0) return 0.5; // No heart rate data

    double avgHR = totalHR / count;

    // Score based on exercise intensity (assuming max HR of 220-age)
    if (avgHR >= 150) return 1.0; // High intensity
    if (avgHR >= 130) return 0.8; // Moderate intensity
    if (avgHR >= 110) return 0.6; // Light intensity
    return 0.4; // Very light
  }

  double _calculateStepsScore(int steps) {
    if (steps >= 10000) return 1.0; // Excellent
    if (steps >= 8000) return 0.9; // Very good
    if (steps >= 6000) return 0.8; // Good
    if (steps >= 5000) return 0.7; // Moderate
    if (steps >= 4000) return 0.6; // Fair
    if (steps >= 3000) return 0.4; // Poor
    if (steps >= 2000) return 0.3; // Very poor
    return 0.2; // Sedentary
  }

  double _calculateActiveMinutesScore(int activeMinutes) {
    if (activeMinutes >= 150) return 1.0; // Excellent (WHO recommendation)
    if (activeMinutes >= 120) return 0.9; // Very good
    if (activeMinutes >= 90) return 0.8; // Good
    if (activeMinutes >= 60) return 0.7; // Moderate
    if (activeMinutes >= 45) return 0.6; // Fair
    if (activeMinutes >= 30) return 0.5; // Poor
    if (activeMinutes >= 15) return 0.3; // Very poor
    return 0.2; // Sedentary
  }

  double _calculateExerciseSessionsScore(int exerciseSessions) {
    if (exerciseSessions >= 5) return 1.0; // Excellent
    if (exerciseSessions >= 4) return 0.9; // Very good
    if (exerciseSessions >= 3) return 0.8; // Good
    if (exerciseSessions >= 2) return 0.7; // Moderate
    if (exerciseSessions >= 1) return 0.6; // Fair
    return 0.3; // Poor
  }

  double _calculateConsistencyScore(UnifiedHealthData data) {
    return data.weeklyActivityConsistency;
  }

  double _calculateStressManagementScore(UnifiedHealthData data) {
    double score = 0;

    // HRV variability (40% of stress management)
    if (data.hrv != null) {
      // Higher HRV indicates better stress management
      if (data.hrv! >= 60)
        score += 1.0 * 0.40;
      else if (data.hrv! >= 50)
        score += 0.8 * 0.40;
      else if (data.hrv! >= 40)
        score += 0.6 * 0.40;
      else
        score += 0.4 * 0.40;
    } else {
      score += 0.6 * 0.40; // Default for missing data
    }

    // Sleep quality as stress indicator (60% of stress management)
    double sleepStressScore = _calculateSleepQualityScore(data.sleep);
    score += sleepStressScore * 0.60;

    return score;
  }

  double _calculateHydrationScore(UnifiedHealthData data) {
    // Placeholder - would integrate with hydration tracking
    // For now, base on activity level (more activity = more hydration needed)
    if (data.activeMinutes >= 150) return 0.8; // High activity
    if (data.activeMinutes >= 90) return 0.9; // Moderate activity
    if (data.activeMinutes >= 60) return 1.0; // Good activity
    return 0.7; // Low activity
  }

  double _calculateNutritionQualityScore(UnifiedHealthData data) {
    // Placeholder - would integrate with nutrition tracking
    // For now, return a default score
    return 0.7; // Default score
  }

  double _calculateMindfulnessScore(UnifiedHealthData data) {
    // Placeholder - would integrate with mindfulness tracking
    // For now, return a default score
    return 0.6; // Default score
  }

  double _calculateMentalHealthIndicatorsScore(UnifiedHealthData data) {
    double score = 0;

    // Sleep quality as mental health indicator (50% of mental health)
    double sleepScore = _calculateSleepQualityScore(data.sleep);
    score += sleepScore * 0.50;

    // Social interaction as mental health indicator (30% of mental health)
    score += data.socialInteractionScore * 0.30;

    // Stress management as mental health indicator (20% of mental health)
    double stressScore = _calculateStressManagementScore(data);
    score += stressScore * 0.20;

    return score;
  }

  double _calculateInteractionScore(UnifiedHealthData data) {
    return data.socialInteractionScore;
  }

  double _calculateSupportScore(UnifiedHealthData data) {
    return data.supportNetworkScore;
  }

  Grade _scoreToGrade(double score) {
    if (score < 0 || score.isNaN) return Grade.red;
    return score >= 0.7
        ? Grade.green
        : score >= 0.4
        ? Grade.amber
        : Grade.red;
  }

  // Fallback methods for manual entry data

  Future<double> _getManualEntryScore(String userId, DateRange range) async {
    try {
      final dates = _getDatesForRange(range);
      double total = 0;
      int count = 0;

      for (final date in dates) {
        final data = _metricsBox.get('${userId}_$date');
        if (data is Map && data['wellness_score'] != null) {
          total += data['wellness_score'] as double;
          count++;
        }
      }

      return count > 0 ? total / count : 0.0;
    } catch (e) {
      print('Error getting manual entry score: $e');
      return 0.0;
    }
  }

  Future<Map<String, Grade>> _getManualEntryGrades(
    String userId,
    DateRange range,
  ) async {
    try {
      final dates = _getDatesForRange(range);
      final grades = <String, Grade>{};

      // For multi-day ranges, aggregate data across days
      if (range == DateRange.weekly ||
          range == DateRange.monthly ||
          range == DateRange.overall) {
        final allHealthData = <UnifiedHealthData>[];

        for (final date in dates) {
          final data = _metricsBox.get('${userId}_$date');
          if (data is Map && data['unified_data'] != null) {
            final unifiedData = Map<String, dynamic>.from(
              data['unified_data'] as Map,
            );
            final healthData = UnifiedHealthData.fromManualEntry(unifiedData);
            allHealthData.add(healthData);
          }
        }

        if (allHealthData.isNotEmpty) {
          // Aggregate data across multiple days for better pattern recognition
          final aggregatedData = _aggregateHealthData(allHealthData);
          return _calculateCategoryGradesWithDateRange(aggregatedData, range);
        }
      } else {
        // For daily view, use the most recent data
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final data = _metricsBox.get('${userId}_$today');
        if (data is Map && data['unified_data'] != null) {
          final unifiedData = Map<String, dynamic>.from(
            data['unified_data'] as Map,
          );
          final healthData = UnifiedHealthData.fromManualEntry(unifiedData);
          return _calculateCategoryGradesWithDateRange(healthData, range);
        }
      }

      return grades;
    } catch (e) {
      print('Error getting manual entry grades: $e');
      return {};
    }
  }

  // NEW: Aggregate health data across multiple days
  UnifiedHealthData _aggregateHealthData(List<UnifiedHealthData> dataList) {
    if (dataList.isEmpty) return UnifiedHealthData.empty();

    // Calculate averages and totals across days
    int totalSteps = 0;
    double? totalHeartRate = 0;
    double? totalHRV = 0;
    int totalActiveMinutes = 0;
    int totalExerciseSessions = 0;
    double totalWeeklyConsistency = 0;
    int totalSedentaryMinutes = 0;
    double totalRestDayAdherence = 0;
    double totalSocialInteractionScore = 0;
    double totalSupportNetworkScore = 0;
    int validDataCount = 0;

    // Sleep data aggregation
    Duration totalSleepDuration = Duration.zero;
    double totalSleepEfficiency = 0;
    double? totalDeepSleepPercentage = 0;
    double? totalRemSleepPercentage = 0;
    int sleepDataCount = 0;

    for (final data in dataList) {
      totalSteps += data.steps;
      if (data.heartRate != null) {
        totalHeartRate = (totalHeartRate ?? 0) + data.heartRate!;
      }
      if (data.hrv != null) {
        totalHRV = (totalHRV ?? 0) + data.hrv!;
      }
      totalActiveMinutes += data.activeMinutes;
      totalExerciseSessions += data.exerciseSessions;
      totalWeeklyConsistency += data.weeklyActivityConsistency;
      totalSedentaryMinutes += data.sedentaryMinutes;
      totalRestDayAdherence += data.restDayAdherence;
      totalSocialInteractionScore += data.socialInteractionScore;
      totalSupportNetworkScore += data.supportNetworkScore;
      validDataCount++;

      // Aggregate sleep data if available
      if (data.sleep != null) {
        totalSleepDuration += data.sleep!.totalSleep;
        totalSleepEfficiency += data.sleep!.sleepEfficiency;
        if (data.sleep!.deepSleepPercentage != null) {
          totalDeepSleepPercentage =
              (totalDeepSleepPercentage ?? 0) +
              data.sleep!.deepSleepPercentage!;
        }
        if (data.sleep!.remSleepPercentage != null) {
          totalRemSleepPercentage =
              (totalRemSleepPercentage ?? 0) + data.sleep!.remSleepPercentage!;
        }
        sleepDataCount++;
      }
    }

    // Calculate averages
    final avgHeartRate = validDataCount > 0
        ? totalHeartRate! / validDataCount
        : null;
    final avgHRV = validDataCount > 0 ? totalHRV! / validDataCount : null;
    final avgWeeklyConsistency = validDataCount > 0
        ? totalWeeklyConsistency / validDataCount
        : 0.5;
    final avgRestDayAdherence = validDataCount > 0
        ? totalRestDayAdherence / validDataCount
        : 0.5;
    final avgSocialInteractionScore = validDataCount > 0
        ? totalSocialInteractionScore / validDataCount
        : 0.5;
    final avgSupportNetworkScore = validDataCount > 0
        ? totalSupportNetworkScore / validDataCount
        : 0.5;

    // Calculate average sleep metrics
    final avgSleepDuration = sleepDataCount > 0
        ? Duration(
            milliseconds: totalSleepDuration.inMilliseconds ~/ sleepDataCount,
          )
        : Duration(hours: 8);
    final avgSleepEfficiency = sleepDataCount > 0
        ? totalSleepEfficiency / sleepDataCount
        : 0.8;
    final avgDeepSleepPercentage = sleepDataCount > 0
        ? totalDeepSleepPercentage! / sleepDataCount
        : null;
    final avgRemSleepPercentage = sleepDataCount > 0
        ? totalRemSleepPercentage! / sleepDataCount
        : null;

    // Create aggregated sleep data
    final aggregatedSleep = SleepData(
      totalSleep: avgSleepDuration,
      sleepEfficiency: avgSleepEfficiency,
      deepSleepPercentage: avgDeepSleepPercentage,
      remSleepPercentage: avgRemSleepPercentage,
      lightSleepPercentage: null, // Not tracked in manual entry
      sleepLatency: Duration(minutes: 15), // Default
      wakeAfterSleepOnset: 0, // Default
      scheduleConsistency: avgWeeklyConsistency, // Use consistency as proxy
      environmentScore: 0.8, // Default
      preSleepRoutineScore: 0.6, // Default
    );

    return UnifiedHealthData(
      steps: totalSteps,
      heartRate: avgHeartRate,
      hrv: avgHRV,
      sleep: aggregatedSleep,
      exercises: null, // Not aggregated
      caloriesBurned: null,
      source: DataSource.manualEntry,
      quality:
          DataQuality.comprehensive, // Aggregated data is more comprehensive
      age: dataList.first.age, // Use first entry's age
      recoveryScore: null, // Not tracked in manual entry
      activeMinutes: totalActiveMinutes,
      exerciseSessions: totalExerciseSessions,
      weeklyActivityConsistency: avgWeeklyConsistency,
      sedentaryMinutes: totalSedentaryMinutes,
      restDayAdherence: avgRestDayAdherence,
      socialInteractionScore: avgSocialInteractionScore,
      supportNetworkScore: avgSupportNetworkScore,
    );
  }

  List<String> _getDatesForRange(DateRange range) {
    try {
      final now = DateTime.now();
      final fmt = DateFormat('yyyy-MM-dd');
      final len = range == DateRange.daily
          ? 1
          : range == DateRange.weekly
          ? 7
          : range == DateRange.monthly
          ? 30
          : 30; // Overall = 30 days

      return List.generate(len, (i) {
        final date = now.subtract(Duration(days: i));
        return fmt.format(date);
      });
    } catch (e) {
      print('Error generating dates: $e');
      return [DateFormat('yyyy-MM-dd').format(DateTime.now())];
    }
  }
}
