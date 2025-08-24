import 'health_data_models.dart';

// Core wellness scoring system with tier-based approach
class WellnessScoringEngine {
  static const Map<String, double> dimensionWeights = {
    'physiological': 0.40, // HRV, sleep, heart rate
    'behavioral': 0.30, // Physical activity, consistency
    'lifestyle': 0.20, // Sleep patterns, recovery
    'social': 0.10, // Social interactions, support
  };

  // Calculate overall wellness score based on available data
  double calculateOverallWellness(UnifiedHealthData data) {
    double score = 0;

    // Calculate each dimension score
    double physiologicalScore = _calculatePhysiologicalScore(data);
    double behavioralScore = _calculateBehavioralScore(data);
    double lifestyleScore = _calculateLifestyleScore(data);
    double socialScore = _calculateSocialScore(data);

    // Apply weights and sum
    score += physiologicalScore * dimensionWeights['physiological']!;
    score += behavioralScore * dimensionWeights['behavioral']!;
    score += lifestyleScore * dimensionWeights['lifestyle']!;
    score += socialScore * dimensionWeights['social']!;

    // Convert to percentage
    return score * 100;
  }

  // Physiological scoring (40% weight)
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
    double heartScore = _calculateHeartScore(
        data.heartRate != null ? HeartRateData(resting: data.heartRate) : null);
    score += heartScore * 0.20;

    // Recovery Score (10% of physiological - if available)
    if (data.recoveryScore != null) {
      score += (data.recoveryScore! / 100.0) * 0.10;
    }

    return score;
  }

  // Behavioral scoring (30% weight)
  double _calculateBehavioralScore(UnifiedHealthData data) {
    double score = 0;

    // Physical activity (50% of behavioral)
    double activityScore = _calculateActivityScore(data);
    score += activityScore * 0.50;

    // Consistency (30% of behavioral)
    double consistencyScore = _calculateConsistencyScore(data);
    score += consistencyScore * 0.30;

    // Movement patterns (20% of behavioral)
    double movementScore = _calculateMovementScore(data);
    score += movementScore * 0.20;

    return score;
  }

  // Lifestyle scoring (20% weight)
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

  // Social scoring (10% weight)
  double _calculateSocialScore(UnifiedHealthData data) {
    double score = 0;

    // Social interactions (50% of social)
    double interactionScore = _calculateInteractionScore(data);
    score += interactionScore * 0.50;

    // Support network (50% of social)
    double supportScore = _calculateSupportScore(data);
    score += supportScore * 0.50;

    return score;
  }

  // HRV scoring with age adjustment
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

  // Sleep scoring
  double _calculateSleepScore(SleepData? sleep) {
    if (sleep == null) return 0.5; // Default score if no data

    double score = 0;

    // Sleep efficiency (30% of sleep score)
    score += (sleep.sleepEfficiency / 100.0) * 0.30;

    // Deep sleep percentage (40% of sleep score)
    if (sleep.deepSleepPercentage != null) {
      double deepSleepScore =
          (sleep.deepSleepPercentage! / 25.0).clamp(0.0, 1.0);
      score += deepSleepScore * 0.40;
    }

    // REM sleep percentage (20% of sleep score)
    if (sleep.remSleepPercentage != null) {
      double remScore = (sleep.remSleepPercentage! / 25.0).clamp(0.0, 1.0);
      score += remScore * 0.20;
    }

    // Sleep duration (10% of sleep score)
    double durationScore = (sleep.totalSleep.inHours / 8.0).clamp(0.0, 1.0);
    score += durationScore * 0.10;

    return score;
  }

  // Heart health scoring
  double _calculateHeartScore(HeartRateData? heartRate) {
    if (heartRate == null) return 0.5; // Default score if no data

    double score = 0;

    // Resting heart rate (60% of heart score)
    if (heartRate.resting != null) {
      double rhrScore = _calculateRHRScore(heartRate.resting!);
      score += rhrScore * 0.60;
    }

    // Heart rate variability during exercise (40% of heart score)
    if (heartRate.exerciseHRV != null) {
      double exerciseHRVScore = (heartRate.exerciseHRV! / 50.0).clamp(0.0, 1.0);
      score += exerciseHRVScore * 0.40;
    }

    return score;
  }

  // Resting heart rate scoring
  double _calculateRHRScore(double rhr) {
    // Optimal RHR is 60-70 bpm
    if (rhr >= 60 && rhr <= 70) return 1.0;
    if (rhr < 60) return 0.8; // Athlete level
    if (rhr <= 80) return 0.6; // Good
    if (rhr <= 90) return 0.4; // Elevated
    return 0.2; // High stress indicator
  }

  // Activity scoring
  double _calculateActivityScore(UnifiedHealthData data) {
    double score = 0;

    // Steps (40% of activity score)
    double stepsScore = (data.steps / 10000.0).clamp(0.0, 1.0);
    score += stepsScore * 0.40;

    // Active minutes (40% of activity score)
    double activeScore = (data.activeMinutes / 150.0).clamp(0.0, 1.0);
    score += activeScore * 0.40;

    // Exercise sessions (20% of activity score)
    double exerciseScore = (data.exerciseSessions / 3.0).clamp(0.0, 1.0);
    score += exerciseScore * 0.20;

    return score;
  }

  // Consistency scoring
  double _calculateConsistencyScore(UnifiedHealthData data) {
    // Calculate consistency over the past week
    return data.weeklyActivityConsistency;
  }

  // Movement scoring
  double _calculateMovementScore(UnifiedHealthData data) {
    // Evaluate movement quality and patterns
    double sedentaryTime = data.sedentaryMinutes / 480.0; // 8 hours baseline
    double movementQuality = 1.0 - sedentaryTime.clamp(0.0, 1.0);
    return movementQuality;
  }

  // Sleep pattern scoring
  double _calculateSleepPatternScore(SleepData? sleep) {
    if (sleep == null) return 0.5;

    double score = 0;

    // Sleep schedule consistency (40% of sleep patterns)
    score += sleep.scheduleConsistency * 0.40;

    // Sleep environment quality (30% of sleep patterns)
    score += sleep.environmentScore * 0.30;

    // Pre-sleep routine (30% of sleep patterns)
    score += sleep.preSleepRoutineScore * 0.30;

    return score;
  }

  // Recovery scoring
  double _calculateRecoveryScore(UnifiedHealthData data) {
    double score = 0;

    // Recovery score from device (60% of recovery)
    if (data.recoveryScore != null) {
      score += (data.recoveryScore! / 100.0) * 0.60;
    }

    // Rest day adherence (40% of recovery)
    score += data.restDayAdherence * 0.40;

    return score;
  }

  // Social interaction scoring
  double _calculateInteractionScore(UnifiedHealthData data) {
    return data.socialInteractionScore;
  }

  // Support network scoring
  double _calculateSupportScore(UnifiedHealthData data) {
    return data.supportNetworkScore;
  }

  // Categorize wellness score
  WellnessCategory categorizeWellness(double score) {
    if (score >= 80) return WellnessCategory.excellent;
    if (score >= 65) return WellnessCategory.good;
    if (score >= 50) return WellnessCategory.moderate;
    if (score >= 35) return WellnessCategory.poor;
    return WellnessCategory.critical;
  }

  // Get wellness insight
  String getWellnessInsight(double score, WellnessCategory category) {
    return _generateInsight(score, category);
  }

  String _generateInsight(double score, WellnessCategory category) {
    switch (category) {
      case WellnessCategory.excellent:
        return "Outstanding wellness! You're maintaining excellent physical and mental health.";
      case WellnessCategory.good:
        return "Great job! Your wellness is in a good range with room for improvement.";
      case WellnessCategory.moderate:
        return "Your wellness is moderate. Focus on sleep, activity, and stress management.";
      case WellnessCategory.poor:
        return "Your wellness needs attention. Consider improving sleep, exercise, and recovery.";
      case WellnessCategory.critical:
        return "Your wellness requires immediate attention. Focus on basic health fundamentals.";
    }
  }
}

// Wellness categories
enum WellnessCategory {
  excellent,
  good,
  moderate,
  poor,
  critical,
}
