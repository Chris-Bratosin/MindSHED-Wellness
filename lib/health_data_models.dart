// Unified health data model that works across all data sources
class UnifiedHealthData {
  final int steps;
  final double? heartRate;
  final double? hrv;
  final SleepData? sleep;
  final List<ExerciseSession>? exercises;
  final double? caloriesBurned;
  final DataSource source;
  final DataQuality quality;
  final int age;
  final double? recoveryScore;
  final int activeMinutes;
  final int exerciseSessions;
  final double weeklyActivityConsistency;
  final int sedentaryMinutes;
  final double restDayAdherence;
  final double socialInteractionScore;
  final double supportNetworkScore;

  UnifiedHealthData({
    required this.steps,
    this.heartRate,
    this.hrv,
    this.sleep,
    this.exercises,
    this.caloriesBurned,
    required this.source,
    required this.quality,
    required this.age,
    this.recoveryScore,
    required this.activeMinutes,
    required this.exerciseSessions,
    required this.weeklyActivityConsistency,
    required this.sedentaryMinutes,
    required this.restDayAdherence,
    required this.socialInteractionScore,
    required this.supportNetworkScore,
  });

  // Factory constructor for creating from different data sources
  factory UnifiedHealthData.fromAppleHealth(Map<String, dynamic> data) {
    return UnifiedHealthData(
      steps: data['steps'] ?? 0,
      heartRate: data['heartRate']?.toDouble(),
      hrv: data['hrv']?.toDouble(),
      sleep: data['sleep'] != null
          ? SleepData.fromAppleHealth(data['sleep'])
          : null,
      exercises: data['exercises'] != null
          ? (data['exercises'] as List)
                .map((e) => ExerciseSession.fromAppleHealth(e))
                .toList()
          : null,
      caloriesBurned: data['caloriesBurned']?.toDouble(),
      source: DataSource.appleHealth,
      quality: DataQuality.comprehensive,
      age: data['age'] ?? 30,
      recoveryScore: data['recoveryScore']?.toDouble(),
      activeMinutes: data['activeMinutes'] ?? 0,
      exerciseSessions: data['exerciseSessions'] ?? 0,
      weeklyActivityConsistency: data['weeklyActivityConsistency'] ?? 0.5,
      sedentaryMinutes: data['sedentaryMinutes'] ?? 480,
      restDayAdherence: data['restDayAdherence'] ?? 0.5,
      socialInteractionScore: data['socialInteractionScore'] ?? 0.5,
      supportNetworkScore: data['supportNetworkScore'] ?? 0.5,
    );
  }

  factory UnifiedHealthData.fromGoogleFit(Map<String, dynamic> data) {
    return UnifiedHealthData(
      steps: data['steps'] ?? 0,
      heartRate: data['heartRate']?.toDouble(),
      hrv: data['hrv']?.toDouble(),
      sleep: data['sleep'] != null
          ? SleepData.fromGoogleFit(data['sleep'])
          : null,
      exercises: data['exercises'] != null
          ? (data['exercises'] as List)
                .map((e) => ExerciseSession.fromGoogleFit(e))
                .toList()
          : null,
      caloriesBurned: data['caloriesBurned']?.toDouble(),
      source: DataSource.googleFit,
      quality: DataQuality.comprehensive,
      age: data['age'] ?? 30,
      recoveryScore: data['recoveryScore']?.toDouble(),
      activeMinutes: data['activeMinutes'] ?? 0,
      exerciseSessions: data['exerciseSessions'] ?? 0,
      weeklyActivityConsistency: data['weeklyActivityConsistency'] ?? 0.5,
      sedentaryMinutes: data['sedentaryMinutes'] ?? 480,
      restDayAdherence: data['restDayAdherence'] ?? 0.5,
      socialInteractionScore: data['socialInteractionScore'] ?? 0.5,
      supportNetworkScore: data['supportNetworkScore'] ?? 0.5,
    );
  }

  factory UnifiedHealthData.fromOuraRing(Map<String, dynamic> data) {
    return UnifiedHealthData(
      steps: data['steps'] ?? 0,
      heartRate: data['heartRate']?.toDouble(),
      hrv: data['hrv']?.toDouble(),
      sleep: data['sleep'] != null
          ? SleepData.fromOuraRing(data['sleep'])
          : null,
      exercises: data['exercises'] != null
          ? (data['exercises'] as List)
                .map((e) => ExerciseSession.fromOuraRing(e))
                .toList()
          : null,
      caloriesBurned: data['caloriesBurned']?.toDouble(),
      source: DataSource.ouraRing,
      quality: DataQuality.premium,
      age: data['age'] ?? 30,
      recoveryScore: data['recoveryScore']?.toDouble(),
      activeMinutes: data['activeMinutes'] ?? 0,
      exerciseSessions: data['exerciseSessions'] ?? 0,
      weeklyActivityConsistency: data['weeklyActivityConsistency'] ?? 0.5,
      sedentaryMinutes: data['sedentaryMinutes'] ?? 480,
      restDayAdherence: data['restDayAdherence'] ?? 0.5,
      socialInteractionScore: data['socialInteractionScore'] ?? 0.5,
      supportNetworkScore: data['supportNetworkScore'] ?? 0.5,
    );
  }

  factory UnifiedHealthData.fromPhoneSensors(Map<String, dynamic> data) {
    return UnifiedHealthData(
      steps: data['steps'] ?? 0,
      heartRate: data['heartRate']?.toDouble(),
      hrv: null, // Phone sensors typically don't provide HRV
      sleep: data['sleep'] != null
          ? SleepData.fromPhoneSensors(data['sleep'])
          : null,
      exercises: null, // Phone sensors don't track exercise sessions
      caloriesBurned: data['caloriesBurned']?.toDouble(),
      source: DataSource.phoneSensors,
      quality: DataQuality.basic,
      age: data['age'] ?? 30,
      recoveryScore: null, // Phone sensors don't provide recovery scores
      activeMinutes: data['activeMinutes'] ?? 0,
      exerciseSessions: 0, // Phone sensors don't track this
      weeklyActivityConsistency: data['weeklyActivityConsistency'] ?? 0.5,
      sedentaryMinutes: data['sedentaryMinutes'] ?? 480,
      restDayAdherence: data['restDayAdherence'] ?? 0.5,
      socialInteractionScore: data['socialInteractionScore'] ?? 0.5,
      supportNetworkScore: data['supportNetworkScore'] ?? 0.5,
    );
  }

  // Create empty data for testing or when no data is available
  factory UnifiedHealthData.empty() {
    return UnifiedHealthData(
      steps: 0,
      heartRate: null,
      hrv: null,
      sleep: null,
      exercises: null,
      caloriesBurned: null,
      source: DataSource.manualEntry,
      quality: DataQuality.minimal,
      age: 30,
      recoveryScore: null,
      activeMinutes: 0,
      exerciseSessions: 0,
      weeklyActivityConsistency: 0.5,
      sedentaryMinutes: 480,
      restDayAdherence: 0.5,
      socialInteractionScore: 0.5,
      supportNetworkScore: 0.5,
    );
  }

  // Create from manual entry data
  factory UnifiedHealthData.fromManualEntry(Map<String, dynamic> data) {
    SleepData? sleepData;
    if (data['sleep_hours'] != null || data['sleep_minutes'] != null) {
      final hours = data['sleep_hours'] as int? ?? 0;
      final minutes = data['sleep_minutes'] as int? ?? 0;
      final totalMinutes = hours * 60 + minutes;

      if (totalMinutes > 0) {
        sleepData = SleepData(
          totalSleep: Duration(minutes: totalMinutes),
          sleepEfficiency: data['sleep_efficiency']?.toDouble() ?? 0.8,
          deepSleepPercentage: null,
          remSleepPercentage: null,
          lightSleepPercentage: null,
          sleepLatency: Duration(minutes: 15),
          wakeAfterSleepOnset: 0,
          scheduleConsistency: data['weekly_consistency']?.toDouble() ?? 0.7,
          environmentScore: 0.8,
          preSleepRoutineScore: 0.7,
        );
      }
    }

    return UnifiedHealthData(
      steps: data['steps'] ?? 0,
      heartRate: data['heart_rate']?.toDouble(),
      hrv: null,
      sleep: sleepData,
      exercises: null,
      caloriesBurned: null,
      source: DataSource.manualEntry,
      quality: DataQuality.minimal,
      age: data['age'] ?? 30,
      recoveryScore: null,
      activeMinutes: data['active_minutes'] ?? 0,
      exerciseSessions: data['mindfulness_activities'] != null
          ? (data['mindfulness_activities'] as List)
                .where((a) => ['Exercise', 'Gym', 'Swimming'].contains(a))
                .length
          : 0,
      weeklyActivityConsistency: data['weekly_consistency']?.toDouble() ?? 0.5,
      sedentaryMinutes: 480,
      restDayAdherence: data['rest_day_adherence']?.toDouble() ?? 0.5,
      socialInteractionScore:
          data['social_interaction_score']?.toDouble() ?? 0.5,
      supportNetworkScore: data['support_network_score']?.toDouble() ?? 0.5,
    );
  }
}

// Sleep data model
class SleepData {
  final Duration totalSleep;
  final double sleepEfficiency;
  final double? deepSleepPercentage;
  final double? remSleepPercentage;
  final double? lightSleepPercentage;
  final Duration sleepLatency;
  final int wakeAfterSleepOnset;
  final double scheduleConsistency;
  final double environmentScore;
  final double preSleepRoutineScore;

  SleepData({
    required this.totalSleep,
    required this.sleepEfficiency,
    this.deepSleepPercentage,
    this.remSleepPercentage,
    this.lightSleepPercentage,
    required this.sleepLatency,
    required this.wakeAfterSleepOnset,
    required this.scheduleConsistency,
    required this.environmentScore,
    required this.preSleepRoutineScore,
  });

  factory SleepData.fromAppleHealth(Map<String, dynamic> data) {
    return SleepData(
      totalSleep: Duration(minutes: data['totalSleepMinutes'] ?? 480),
      sleepEfficiency: data['sleepEfficiency'] ?? 0.8,
      deepSleepPercentage: data['deepSleepPercentage']?.toDouble(),
      remSleepPercentage: data['remSleepPercentage']?.toDouble(),
      lightSleepPercentage: data['lightSleepPercentage']?.toDouble(),
      sleepLatency: Duration(minutes: data['sleepLatencyMinutes'] ?? 15),
      wakeAfterSleepOnset: data['wakeAfterSleepOnset'] ?? 0,
      scheduleConsistency: data['scheduleConsistency'] ?? 0.7,
      environmentScore: data['environmentScore'] ?? 0.8,
      preSleepRoutineScore: data['preSleepRoutineScore'] ?? 0.6,
    );
  }

  factory SleepData.fromGoogleFit(Map<String, dynamic> data) {
    return SleepData(
      totalSleep: Duration(minutes: data['totalSleepMinutes'] ?? 480),
      sleepEfficiency: data['sleepEfficiency'] ?? 0.8,
      deepSleepPercentage: null, // Google Fit typically doesn't provide this
      remSleepPercentage: null, // Google Fit typically doesn't provide this
      lightSleepPercentage: null, // Google Fit typically doesn't provide this
      sleepLatency: Duration(minutes: data['sleepLatencyMinutes'] ?? 15),
      wakeAfterSleepOnset: data['wakeAfterSleepOnset'] ?? 0,
      scheduleConsistency: data['scheduleConsistency'] ?? 0.7,
      environmentScore: data['environmentScore'] ?? 0.8,
      preSleepRoutineScore: data['preSleepRoutineScore'] ?? 0.6,
    );
  }

  factory SleepData.fromOuraRing(Map<String, dynamic> data) {
    return SleepData(
      totalSleep: Duration(minutes: data['totalSleepMinutes'] ?? 480),
      sleepEfficiency: data['sleepEfficiency'] ?? 0.8,
      deepSleepPercentage: data['deepSleepPercentage']?.toDouble(),
      remSleepPercentage: data['remSleepPercentage']?.toDouble(),
      lightSleepPercentage: data['lightSleepPercentage']?.toDouble(),
      sleepLatency: Duration(minutes: data['sleepLatencyMinutes'] ?? 15),
      wakeAfterSleepOnset: data['wakeAfterSleepOnset'] ?? 0,
      scheduleConsistency: data['scheduleConsistency'] ?? 0.7,
      environmentScore: data['environmentScore'] ?? 0.8,
      preSleepRoutineScore: data['preSleepRoutineScore'] ?? 0.6,
    );
  }

  factory SleepData.fromPhoneSensors(Map<String, dynamic> data) {
    return SleepData(
      totalSleep: Duration(minutes: data['totalSleepMinutes'] ?? 480),
      sleepEfficiency: data['sleepEfficiency'] ?? 0.8,
      deepSleepPercentage: null, // Phone sensors can't detect sleep stages
      remSleepPercentage: null, // Phone sensors can't detect sleep stages
      lightSleepPercentage: null, // Phone sensors can't detect sleep stages
      sleepLatency: Duration(minutes: data['sleepLatencyMinutes'] ?? 15),
      wakeAfterSleepOnset: data['wakeAfterSleepOnset'] ?? 0,
      scheduleConsistency: data['scheduleConsistency'] ?? 0.7,
      environmentScore: data['environmentScore'] ?? 0.8,
      preSleepRoutineScore: data['preSleepRoutineScore'] ?? 0.6,
    );
  }
}

// Heart rate data model
class HeartRateData {
  final double? resting;
  final double? max;
  final double? average;
  final double? exerciseHRV;
  final double? recoveryHRV;

  HeartRateData({
    this.resting,
    this.max,
    this.average,
    this.exerciseHRV,
    this.recoveryHRV,
  });

  factory HeartRateData.fromAppleHealth(Map<String, dynamic> data) {
    return HeartRateData(
      resting: data['restingHeartRate']?.toDouble(),
      max: data['maxHeartRate']?.toDouble(),
      average: data['averageHeartRate']?.toDouble(),
      exerciseHRV: data['exerciseHRV']?.toDouble(),
      recoveryHRV: data['recoveryHRV']?.toDouble(),
    );
  }

  factory HeartRateData.fromGoogleFit(Map<String, dynamic> data) {
    return HeartRateData(
      resting: data['restingHeartRate']?.toDouble(),
      max: data['maxHeartRate']?.toDouble(),
      average: data['averageHeartRate']?.toDouble(),
      exerciseHRV: data['exerciseHRV']?.toDouble(),
      recoveryHRV: data['recoveryHRV']?.toDouble(),
    );
  }

  factory HeartRateData.fromOuraRing(Map<String, dynamic> data) {
    return HeartRateData(
      resting: data['restingHeartRate']?.toDouble(),
      max: data['maxHeartRate']?.toDouble(),
      average: data['averageHeartRate']?.toDouble(),
      exerciseHRV: data['exerciseHRV']?.toDouble(),
      recoveryHRV: data['recoveryHRV']?.toDouble(),
    );
  }
}

// Exercise session model
class ExerciseSession {
  final String type;
  final Duration duration;
  final double? caloriesBurned;
  final double? averageHeartRate;
  final double? maxHeartRate;
  final double? distance;
  final DateTime startTime;

  ExerciseSession({
    required this.type,
    required this.duration,
    this.caloriesBurned,
    this.averageHeartRate,
    this.maxHeartRate,
    this.distance,
    required this.startTime,
  });

  factory ExerciseSession.fromAppleHealth(Map<String, dynamic> data) {
    return ExerciseSession(
      type: data['type'] ?? 'Unknown',
      duration: Duration(minutes: data['durationMinutes'] ?? 30),
      caloriesBurned: data['caloriesBurned']?.toDouble(),
      averageHeartRate: data['averageHeartRate']?.toDouble(),
      maxHeartRate: data['maxHeartRate']?.toDouble(),
      distance: data['distance']?.toDouble(),
      startTime: DateTime.parse(
        data['startTime'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  factory ExerciseSession.fromGoogleFit(Map<String, dynamic> data) {
    return ExerciseSession(
      type: data['type'] ?? 'Unknown',
      duration: Duration(minutes: data['durationMinutes'] ?? 30),
      caloriesBurned: data['caloriesBurned']?.toDouble(),
      averageHeartRate: data['averageHeartRate']?.toDouble(),
      maxHeartRate: data['maxHeartRate']?.toDouble(),
      distance: data['distance']?.toDouble(),
      startTime: DateTime.parse(
        data['startTime'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  factory ExerciseSession.fromOuraRing(Map<String, dynamic> data) {
    return ExerciseSession(
      type: data['type'] ?? 'Unknown',
      duration: Duration(minutes: data['durationMinutes'] ?? 30),
      caloriesBurned: data['caloriesBurned']?.toDouble(),
      averageHeartRate: data['averageHeartRate']?.toDouble(),
      maxHeartRate: data['maxHeartRate']?.toDouble(),
      distance: data['distance']?.toDouble(),
      startTime: DateTime.parse(
        data['startTime'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

// Data source enum
enum DataSource { appleHealth, googleFit, ouraRing, phoneSensors, manualEntry }

// Data quality enum
enum DataQuality {
  premium, // Oura Ring, detailed Apple Health
  comprehensive, // Apple Health, Google Fit
  basic, // Phone sensors
  minimal, // Manual entry
}
