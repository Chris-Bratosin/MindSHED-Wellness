import 'health_data_models.dart';

// Core wellness scoring system with tier-based approach
class WellnessScoringEngine {
  // Updated dimension weights for 8 categories
  static const Map<String, double> dimensionWeights = {
    'sleep_health': 0.25, // Sleep duration, efficiency, patterns
    'cardiovascular': 0.15, // Heart rate, HRV, heart health
    'physical_activity': 0.20, // Steps, active minutes, exercise
    'consistency_habits': 0.10, // Weekly consistency, movement patterns
    'recovery_stress': 0.15, // Recovery scores, stress management
    'social_wellness': 0.10, // Social interactions, support network
    'nutrition_hydration': 0.03, // Hydration, nutrition quality
    'mental_wellness': 0.02, // Mindfulness, mental health indicators
  };

  double calculateOverallWellness(UnifiedHealthData data) {
    double score = 0;

    // Calculate scores for each dimension
    score +=
        _calculateSleepHealthScore(data) * dimensionWeights['sleep_health']!;
    score +=
        _calculateCardiovascularScore(data) *
        dimensionWeights['cardiovascular']!;
    score +=
        _calculatePhysicalActivityScore(data) *
        dimensionWeights['physical_activity']!;
    score +=
        _calculateConsistencyHabitsScore(data) *
        dimensionWeights['consistency_habits']!;
    score +=
        _calculateRecoveryStressScore(data) *
        dimensionWeights['recovery_stress']!;
    score +=
        _calculateSocialWellnessScore(data) *
        dimensionWeights['social_wellness']!;
    score +=
        _calculateNutritionHydrationScore(data) *
        dimensionWeights['nutrition_hydration']!;
    score +=
        _calculateMentalWellnessScore(data) *
        dimensionWeights['mental_wellness']!;

    // Convert to percentage
    return score * 100;
  }

  // Sleep Health scoring (25% weight) - Comprehensive sleep metrics
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

  // Cardiovascular scoring (15% weight) - Heart health metrics
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

  // Physical Activity scoring (20% weight) - Movement and exercise
  double _calculatePhysicalActivityScore(UnifiedHealthData data) {
    double score = 0;

    // Steps (40% of physical activity)
    if (data.steps != null) {
      double stepsScore = _calculateStepsScore(data.steps!);
      score += stepsScore * 0.40;
    } else {
      score += 0.5 * 0.40; // Default for missing steps
    }

    // Active minutes (35% of physical activity)
    if (data.activeMinutes != null) {
      double activeScore = _calculateActiveMinutesScore(data.activeMinutes!);
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

  // Consistency & Habits scoring (10% weight) - Weekly patterns
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

  // Recovery & Stress scoring (15% weight) - Recovery and stress management
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

  // Social Wellness scoring (10% weight) - Social connections
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

  // Nutrition & Hydration scoring (3% weight) - Basic nutrition metrics
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

  // Mental Wellness scoring (2% weight) - Mental health indicators
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

  // HRV scoring with age adjustment - IMPROVED
  double _calculateHRVScore(double hrv, int age) {
    // Age-adjusted HRV scoring based on research
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

  // Sleep scoring - IMPROVED
  double _calculateSleepScore(SleepData? sleep) {
    if (sleep == null) return 0.6; // Increased default score if no data

    double score = 0;

    // Sleep duration (40% of sleep score) - INCREASED WEIGHT
    double durationScore = _calculateSleepDurationScore(sleep.totalSleep);
    score += durationScore * 0.40;

    // Sleep efficiency (30% of sleep score)
    score += (sleep.sleepEfficiency) * 0.30;

    // Deep sleep percentage (20% of sleep score) - Only if available
    if (sleep.deepSleepPercentage != null) {
      double deepSleepScore = (sleep.deepSleepPercentage! / 25.0).clamp(
        0.0,
        1.0,
      );
      score += deepSleepScore * 0.20;
    } else {
      // Don't penalize for missing deep sleep data
      score += 0.7 * 0.20; // Give 70% for missing deep sleep
    }

    // REM sleep percentage (10% of sleep score) - Only if available
    if (sleep.remSleepPercentage != null) {
      double remScore = (sleep.remSleepPercentage! / 25.0).clamp(0.0, 1.0);
      score += remScore * 0.10;
    } else {
      // Don't penalize for missing REM sleep data
      score += 0.7 * 0.10; // Give 70% for missing REM sleep
    }

    return score;
  }

  // NEW: Sleep duration scoring based on research
  double _calculateSleepDurationScore(Duration sleepDuration) {
    double hours =
        sleepDuration.inHours + (sleepDuration.inMinutes % 60) / 60.0;

    // Based on research: 7-9 hours is optimal, 6-7 is good, 5-6 is moderate
    if (hours >= 7.0 && hours <= 9.0) return 1.0; // Optimal
    if (hours >= 6.5 && hours < 7.0) return 0.9; // Very good
    if (hours >= 6.0 && hours < 6.5) return 0.8; // Good
    if (hours >= 5.5 && hours < 6.0) return 0.6; // Moderate
    if (hours >= 5.0 && hours < 5.5) return 0.4; // Poor
    if (hours >= 9.0 && hours <= 10.0) return 0.8; // Too much sleep
    if (hours > 10.0) return 0.3; // Excessive sleep
    return 0.2; // Very poor (<5 hours)
  }

  // Heart health scoring - IMPROVED
  double _calculateHeartScore(HeartRateData? heartRate) {
    if (heartRate == null) return 0.7; // Increased default score if no data

    double score = 0;

    // Resting heart rate (80% of heart score) - Increased weight
    if (heartRate.resting != null) {
      double rhrScore = _calculateRHRScore(heartRate.resting!);
      score += rhrScore * 0.80;
    }

    // Heart rate variability during exercise (20% of heart score) - Reduced weight
    if (heartRate.exerciseHRV != null) {
      double exerciseHRVScore = (heartRate.exerciseHRV! / 50.0).clamp(0.0, 1.0);
      score += exerciseHRVScore * 0.20;
    }

    return score;
  }

  // Resting heart rate scoring - IMPROVED
  double _calculateRHRScore(double rhr) {
    // Improved RHR scoring based on research
    if (rhr >= 50 && rhr <= 70) return 1.0; // Excellent (includes athletes)
    if (rhr >= 45 && rhr < 50) return 0.9; // Very good (athlete level)
    if (rhr >= 70 && rhr <= 80) return 0.8; // Good
    if (rhr >= 40 && rhr < 45) return 0.8; // Good (elite athlete)
    if (rhr >= 80 && rhr <= 90) return 0.6; // Moderate
    if (rhr >= 90 && rhr <= 100) return 0.4; // Elevated
    if (rhr > 100) return 0.2; // High stress indicator
    return 0.3; // Very low (could be concerning)
  }

  // Activity scoring - IMPROVED
  double _calculateActivityScore(UnifiedHealthData data) {
    double score = 0;

    // Steps (40% of activity score) - IMPROVED THRESHOLDS
    double stepsScore = _calculateStepsScore(data.steps);
    score += stepsScore * 0.40;

    // Active minutes (40% of activity score) - IMPROVED THRESHOLDS
    double activeScore = _calculateActiveMinutesScore(data.activeMinutes);
    score += activeScore * 0.40;

    // Exercise sessions (20% of activity score) - IMPROVED THRESHOLDS
    double exerciseScore = _calculateExerciseSessionsScore(
      data.exerciseSessions,
    );
    score += exerciseScore * 0.20;

    return score;
  }

  // NEW: Improved steps scoring
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

  // NEW: Improved active minutes scoring
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

  // NEW: Improved exercise sessions scoring
  double _calculateExerciseSessionsScore(int exerciseSessions) {
    if (exerciseSessions >= 5) return 1.0; // Excellent
    if (exerciseSessions >= 4) return 0.9; // Very good
    if (exerciseSessions >= 3) return 0.8; // Good
    if (exerciseSessions >= 2) return 0.7; // Moderate
    if (exerciseSessions >= 1) return 0.6; // Fair
    return 0.3; // Poor
  }

  // Consistency scoring - UNCHANGED
  double _calculateConsistencyScore(UnifiedHealthData data) {
    // Calculate consistency over the past week
    return data.weeklyActivityConsistency;
  }

  // Movement scoring - IMPROVED
  double _calculateMovementScore(UnifiedHealthData data) {
    // Evaluate movement quality and patterns - Less punitive
    double sedentaryTime =
        data.sedentaryMinutes / 600.0; // 10 hours baseline (more realistic)
    double movementQuality = 1.0 - sedentaryTime.clamp(0.0, 1.0);
    return movementQuality;
  }

  // Sleep pattern scoring - IMPROVED
  double _calculateSleepPatternScore(SleepData? sleep) {
    if (sleep == null) return 0.6; // Increased default score

    double score = 0;

    // Sleep schedule consistency (40% of sleep patterns)
    score += sleep.scheduleConsistency * 0.40;

    // Sleep environment quality (30% of sleep patterns)
    score += sleep.environmentScore * 0.30;

    // Pre-sleep routine (30% of sleep patterns)
    score += sleep.preSleepRoutineScore * 0.30;

    return score;
  }

  // Recovery scoring - IMPROVED
  double _calculateRecoveryScore(UnifiedHealthData data) {
    double score = 0;

    // Recovery score from device (60% of recovery)
    if (data.recoveryScore != null) {
      score += (data.recoveryScore! / 100.0) * 0.60;
    } else {
      // Don't penalize for missing recovery data
      score += 0.7 * 0.60; // Give 70% for missing recovery data
    }

    // Rest day adherence (40% of recovery)
    score += data.restDayAdherence * 0.40;

    return score;
  }

  // Social interaction scoring - UNCHANGED
  double _calculateInteractionScore(UnifiedHealthData data) {
    return data.socialInteractionScore;
  }

  // Support network scoring - UNCHANGED
  double _calculateSupportScore(UnifiedHealthData data) {
    return data.supportNetworkScore;
  }

  // Categorize wellness score - IMPROVED THRESHOLDS
  WellnessCategory categorizeWellness(double score) {
    if (score >= 85) return WellnessCategory.excellent;
    if (score >= 70) return WellnessCategory.good;
    if (score >= 55) return WellnessCategory.moderate;
    if (score >= 40) return WellnessCategory.poor;
    return WellnessCategory.critical;
  }

  // Get wellness insight - IMPROVED
  String getWellnessInsight(double score, WellnessCategory category) {
    return _generateInsight(score, category);
  }

  // NEW: Sleep efficiency scoring
  double _calculateSleepEfficiencyScore(double efficiency) {
    if (efficiency >= 0.95) return 1.0; // Excellent
    if (efficiency >= 0.90) return 0.9; // Very good
    if (efficiency >= 0.85) return 0.8; // Good
    if (efficiency >= 0.80) return 0.7; // Moderate
    if (efficiency >= 0.75) return 0.6; // Fair
    if (efficiency >= 0.70) return 0.4; // Poor
    return 0.2; // Very poor
  }

  // NEW: Sleep quality scoring (deep/REM sleep)
  double _calculateSleepQualityScore(SleepData? sleep) {
    if (sleep == null) return 0.7; // Default for missing data

    double score = 0;

    // Deep sleep percentage (60% of quality)
    if (sleep.deepSleepPercentage != null) {
      if (sleep.deepSleepPercentage! >= 20) return 1.0; // Excellent
      if (sleep.deepSleepPercentage! >= 15) return 0.8; // Good
      if (sleep.deepSleepPercentage! >= 10) return 0.6; // Moderate
      score += 0.4 * 0.60; // Poor
    } else {
      score += 0.7 * 0.60; // Default for missing data
    }

    // REM sleep percentage (40% of quality)
    if (sleep.remSleepPercentage != null) {
      if (sleep.remSleepPercentage! >= 25) return 1.0; // Excellent
      if (sleep.remSleepPercentage! >= 20) return 0.8; // Good
      if (sleep.remSleepPercentage! >= 15) return 0.6; // Moderate
      score += 0.4 * 0.40; // Poor
    } else {
      score += 0.7 * 0.40; // Default for missing data
    }

    return score;
  }

  // NEW: Sleep consistency scoring
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

  // NEW: Exercise heart rate scoring
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

  // NEW: Stress management scoring
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

  // NEW: Hydration scoring
  double _calculateHydrationScore(UnifiedHealthData data) {
    // Placeholder - would integrate with hydration tracking
    // For now, base on activity level (more activity = more hydration needed)
    if (data.activeMinutes >= 150) return 0.8; // High activity
    if (data.activeMinutes >= 90) return 0.9; // Moderate activity
    if (data.activeMinutes >= 60) return 1.0; // Good activity
    return 0.7; // Low activity
  }

  // NEW: Nutrition quality scoring
  double _calculateNutritionQualityScore(UnifiedHealthData data) {
    // Placeholder - would integrate with nutrition tracking
    // For now, return a default score
    return 0.7; // Default score
  }

  // NEW: Mindfulness activities scoring
  double _calculateMindfulnessScore(UnifiedHealthData data) {
    // Placeholder - would integrate with mindfulness tracking
    // For now, return a default score
    return 0.6; // Default score
  }

  // NEW: Mental health indicators scoring
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

  String _generateInsight(double score, WellnessCategory category) {
    switch (category) {
      case WellnessCategory.excellent:
        return "Outstanding wellness! You're maintaining excellent physical and mental health. Keep up the great work!";
      case WellnessCategory.good:
        return "Great job! Your wellness is in a good range. Small improvements in sleep or activity could boost you to excellent.";
      case WellnessCategory.moderate:
        return "Your wellness is moderate. Focus on getting 7-9 hours of sleep, 30+ minutes of activity, and stress management.";
      case WellnessCategory.poor:
        return "Your wellness needs attention. Prioritize sleep, regular exercise, and recovery. Consider consulting a healthcare provider.";
      case WellnessCategory.critical:
        return "Your wellness requires immediate attention. Focus on basic health fundamentals: sleep, nutrition, and movement.";
    }
  }
}

// Wellness categories
enum WellnessCategory { excellent, good, moderate, poor, critical }
