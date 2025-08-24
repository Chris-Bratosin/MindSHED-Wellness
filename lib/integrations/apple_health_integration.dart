import 'dart:io';
import 'package:health/health.dart';
import '../health_data_models.dart';
import '../data_source_manager.dart';

// Real Apple HealthKit integration
class AppleHealthIntegration {
  static final HealthFactory _health = HealthFactory();

  // Health data types we want to access
  static const List<HealthDataType> _dataTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.BASAL_ENERGY_BURNED,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.EXERCISE_TIME,
    HealthDataType.WORKOUT,
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.BODY_MASS_INDEX,
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.BODY_TEMPERATURE,
  ];

  // Check if HealthKit is available
  static Future<bool> isAvailable() async {
    if (!Platform.isIOS) return false;

    try {
      return await _health.isHealthDataAvailable();
    } catch (e) {
      print('Error checking HealthKit availability: $e');
      return false;
    }
  }

  // Request HealthKit permissions
  static Future<bool> requestPermissions() async {
    if (!Platform.isIOS) return false;

    try {
      // Request authorization for all data types
      bool authorized = await _health.requestAuthorization(_dataTypes);

      if (authorized) {
        print('✅ HealthKit permissions granted');
        return true;
      } else {
        print('❌ HealthKit permissions denied');
        return false;
      }
    } catch (e) {
      print('Error requesting HealthKit permissions: $e');
      return false;
    }
  }

  // Check current authorization status
  static Future<Map<HealthDataType, bool>> checkPermissions() async {
    if (!Platform.isIOS) return {};

    try {
      Map<HealthDataType, bool> permissions = {};

      for (HealthDataType type in _dataTypes) {
        permissions[type] = await _health.hasPermissions([type]);
      }

      return permissions;
    } catch (e) {
      print('Error checking HealthKit permissions: $e');
      return {};
    }
  }

  // Fetch health data for a specific date range
  static Future<UnifiedHealthData> fetchHealthData(DateTimeRange range) async {
    if (!Platform.isIOS) {
      throw UnsupportedError('HealthKit is only available on iOS');
    }

    try {
      print('🔄 Fetching Apple Health data...');

      // Fetch steps
      int steps = await _fetchSteps(range);

      // Fetch heart rate data
      HeartRateData? heartRate = await _fetchHeartRateData(range);

      // Fetch sleep data
      SleepData? sleep = await _fetchSleepData(range);

      // Fetch exercise data
      List<ExerciseSession>? exercises = await _fetchExerciseData(range);

      // Fetch calories
      double? caloriesBurned = await _fetchCalories(range);

      // Fetch active minutes
      int activeMinutes = await _fetchActiveMinutes(range);

      // Calculate derived metrics
      double weeklyConsistency = await _calculateWeeklyConsistency(range);
      int sedentaryMinutes = await _calculateSedentaryTime(range);
      double restDayAdherence = await _calculateRestDayAdherence(range);

      print('✅ Apple Health data fetched successfully');

      return UnifiedHealthData(
        steps: steps,
        heartRate: heartRate?.resting,
        hrv: heartRate?.exerciseHRV,
        sleep: sleep,
        exercises: exercises,
        caloriesBurned: caloriesBurned,
        source: DataSource.appleHealth,
        quality: DataQuality.comprehensive,
        age: 30, // TODO: Get from user profile
        recoveryScore: null, // HealthKit doesn't provide recovery scores
        activeMinutes: activeMinutes,
        exerciseSessions: exercises?.length ?? 0,
        weeklyActivityConsistency: weeklyConsistency,
        sedentaryMinutes: sedentaryMinutes,
        restDayAdherence: restDayAdherence,
        socialInteractionScore: 0.7, // TODO: Get from other sources
        supportNetworkScore: 0.8, // TODO: Get from other sources
      );
    } catch (e) {
      print('Error fetching Apple Health data: $e');
      rethrow;
    }
  }

  // Fetch steps for date range
  static Future<int> _fetchSteps(DateTimeRange range) async {
    try {
      List<HealthDataPoint> stepsData = await _health.getHealthDataFromTypes(
        range.start,
        range.end,
        [HealthDataType.STEPS],
      );

      int totalSteps = 0;
      for (HealthDataPoint point in stepsData) {
        totalSteps += point.value.round();
      }

      return totalSteps;
    } catch (e) {
      print('Error fetching steps: $e');
      return 0;
    }
  }

  // Fetch heart rate data
  static Future<HeartRateData?> _fetchHeartRateData(DateTimeRange range) async {
    try {
      List<HealthDataPoint> hrData = await _health.getHealthDataFromTypes(
        range.start,
        range.end,
        [HealthDataType.HEART_RATE],
      );

      if (hrData.isEmpty) return null;

      // Calculate resting heart rate (morning baseline)
      double restingHR = _calculateRestingHeartRate(hrData);

      // Calculate max heart rate
      double maxHR = hrData.map((p) => p.value).reduce((a, b) => a > b ? a : b);

      // Calculate average heart rate
      double avgHR =
          hrData.map((p) => p.value).reduce((a, b) => a + b) / hrData.length;

      return HeartRateData(
        resting: restingHR,
        max: maxHR,
        average: avgHR,
        exerciseHRV: null, // HealthKit doesn't provide HRV directly
        recoveryHRV: null,
      );
    } catch (e) {
      print('Error fetching heart rate data: $e');
      return null;
    }
  }

  // Fetch sleep data
  static Future<SleepData?> _fetchSleepData(DateTimeRange range) async {
    try {
      // Fetch sleep in bed time
      List<HealthDataPoint> inBedData = await _health.getHealthDataFromTypes(
        range.start,
        range.end,
        [HealthDataType.SLEEP_IN_BED],
      );

      // Fetch actual sleep time
      List<HealthDataPoint> asleepData = await _health.getHealthDataFromTypes(
        range.start,
        range.end,
        [HealthDataType.SLEEP_ASLEEP],
      );

      // Fetch deep sleep
      List<HealthDataPoint> deepSleepData =
          await _health.getHealthDataFromTypes(
        range.start,
        range.end,
        [HealthDataType.SLEEP_DEEP],
      );

      // Fetch REM sleep
      List<HealthDataPoint> remSleepData = await _health.getHealthDataFromTypes(
        range.start,
        range.end,
        [HealthDataType.SLEEP_REM],
      );

      // Fetch light sleep
      List<HealthDataPoint> lightSleepData =
          await _health.getHealthDataFromTypes(
        range.start,
        range.end,
        [HealthDataType.SLEEP_LIGHT],
      );

      if (inBedData.isEmpty || asleepData.isEmpty) return null;

      // Calculate total sleep duration
      Duration totalSleep = _calculateTotalSleep(asleepData);

      // Calculate sleep efficiency
      Duration timeInBed = _calculateTotalTime(inBedData);
      double sleepEfficiency = totalSleep.inMinutes / timeInBed.inMinutes;

      // Calculate sleep stages percentages
      double? deepSleepPercentage =
          _calculateSleepStagePercentage(deepSleepData, totalSleep);
      double? remSleepPercentage =
          _calculateSleepStagePercentage(remSleepData, totalSleep);
      double? lightSleepPercentage =
          _calculateSleepStagePercentage(lightSleepData, totalSleep);

      // Estimate sleep latency (time to fall asleep)
      Duration sleepLatency = _estimateSleepLatency(inBedData, asleepData);

      return SleepData(
        totalSleep: totalSleep,
        sleepEfficiency: sleepEfficiency.clamp(0.0, 1.0),
        deepSleepPercentage: deepSleepPercentage,
        remSleepPercentage: remSleepPercentage,
        lightSleepPercentage: lightSleepPercentage,
        sleepLatency: sleepLatency,
        wakeAfterSleepOnset: 0, // TODO: Calculate from sleep data
        scheduleConsistency: 0.8, // TODO: Calculate from historical data
        environmentScore: 0.8, // TODO: Get from user settings
        preSleepRoutineScore: 0.7, // TODO: Get from user settings
      );
    } catch (e) {
      print('Error fetching sleep data: $e');
      return null;
    }
  }

  // Fetch exercise data
  static Future<List<ExerciseSession>?> _fetchExerciseData(
      DateTimeRange range) async {
    try {
      List<HealthDataPoint> workoutData = await _health.getHealthDataFromTypes(
        range.start,
        range.end,
        [HealthDataType.WORKOUT],
      );

      if (workoutData.isEmpty) return null;

      List<ExerciseSession> sessions = [];

      for (HealthDataPoint workout in workoutData) {
        // Get workout type from metadata
        String workoutType = _getWorkoutType(workout);

        // Calculate duration
        Duration duration = workout.dateTo.difference(workout.dateFrom);

        // Get calories burned if available
        double? calories = workout.value > 0 ? workout.value : null;

        sessions.add(ExerciseSession(
          type: workoutType,
          duration: duration,
          caloriesBurned: calories,
          averageHeartRate: null, // TODO: Calculate from heart rate data
          maxHeartRate: null, // TODO: Calculate from heart rate data
          distance: null, // TODO: Get from distance data
          startTime: workout.dateFrom,
        ));
      }

      return sessions;
    } catch (e) {
      print('Error fetching exercise data: $e');
      return null;
    }
  }

  // Fetch calories burned
  static Future<double?> _fetchCalories(DateTimeRange range) async {
    try {
      List<HealthDataPoint> activeCalories =
          await _health.getHealthDataFromTypes(
        range.start,
        range.end,
        [HealthDataType.ACTIVE_ENERGY_BURNED],
      );

      List<HealthDataPoint> basalCalories =
          await _health.getHealthDataFromTypes(
        range.start,
        range.end,
        [HealthDataType.BASAL_ENERGY_BURNED],
      );

      double totalCalories = 0;

      // Add active calories
      for (HealthDataPoint point in activeCalories) {
        totalCalories += point.value;
      }

      // Add basal calories (for the day)
      for (HealthDataPoint point in basalCalories) {
        totalCalories += point.value;
      }

      return totalCalories > 0 ? totalCalories : null;
    } catch (e) {
      print('Error fetching calories: $e');
      return null;
    }
  }

  // Fetch active minutes
  static Future<int> _fetchActiveMinutes(DateTimeRange range) async {
    try {
      List<HealthDataPoint> exerciseTime = await _health.getHealthDataFromTypes(
        range.start,
        range.end,
        [HealthDataType.EXERCISE_TIME],
      );

      int totalMinutes = 0;
      for (HealthDataPoint point in exerciseTime) {
        totalMinutes += point.value.round();
      }

      return totalMinutes;
    } catch (e) {
      print('Error fetching active minutes: $e');
      return 0;
    }
  }

  // Helper methods

  static double _calculateRestingHeartRate(List<HealthDataPoint> hrData) {
    // Find heart rate measurements in the morning (6-9 AM)
    List<HealthDataPoint> morningHR = hrData.where((point) {
      int hour = point.dateFrom.hour;
      return hour >= 6 && hour <= 9;
    }).toList();

    if (morningHR.isEmpty) {
      // If no morning data, use the lowest heart rate
      return hrData.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    }

    // Calculate average of morning heart rates
    double sum = morningHR.map((p) => p.value).reduce((a, b) => a + b);
    return sum / morningHR.length;
  }

  static Duration _calculateTotalSleep(List<HealthDataPoint> sleepData) {
    int totalMinutes = 0;
    for (HealthDataPoint point in sleepData) {
      totalMinutes += point.dateTo.difference(point.dateFrom).inMinutes;
    }
    return Duration(minutes: totalMinutes);
  }

  static Duration _calculateTotalTime(List<HealthDataPoint> timeData) {
    int totalMinutes = 0;
    for (HealthDataPoint point in timeData) {
      totalMinutes += point.dateTo.difference(point.dateFrom).inMinutes;
    }
    return Duration(minutes: totalMinutes);
  }

  static double? _calculateSleepStagePercentage(
      List<HealthDataPoint> stageData, Duration totalSleep) {
    if (stageData.isEmpty || totalSleep.inMinutes == 0) return null;

    int stageMinutes = 0;
    for (HealthDataPoint point in stageData) {
      stageMinutes += point.dateTo.difference(point.dateFrom).inMinutes;
    }

    return (stageMinutes / totalSleep.inMinutes) * 100;
  }

  static Duration _estimateSleepLatency(
      List<HealthDataPoint> inBedData, List<HealthDataPoint> asleepData) {
    if (inBedData.isEmpty || asleepData.isEmpty) return Duration(minutes: 15);

    // Find the first time in bed and first time asleep for the same night
    DateTime firstInBed = inBedData.first.dateFrom;
    DateTime firstAsleep = asleepData.first.dateFrom;

    return firstAsleep.difference(firstInBed);
  }

  static String _getWorkoutType(HealthDataPoint workout) {
    // Try to get workout type from metadata
    if (workout.metaData.containsKey('HKWorkoutActivityType')) {
      int activityType = workout.metaData['HKWorkoutActivityType'] as int;
      return _mapWorkoutType(activityType);
    }

    return 'Exercise';
  }

  static String _mapWorkoutType(int activityType) {
    // Map HealthKit workout types to readable names
    switch (activityType) {
      case 3:
        return 'Running';
      case 37:
        return 'Walking';
      case 16:
        return 'Cycling';
      case 13:
        return 'Swimming';
      case 52:
        return 'Strength Training';
      case 48:
        return 'Yoga';
      case 47:
        return 'Pilates';
      case 45:
        return 'Dancing';
      default:
        return 'Exercise';
    }
  }

  static Future<double> _calculateWeeklyConsistency(DateTimeRange range) async {
    // TODO: Implement weekly consistency calculation
    // This would compare activity levels across multiple days
    return 0.8; // Placeholder
  }

  static Future<int> _calculateSedentaryTime(DateTimeRange range) async {
    // TODO: Implement sedentary time calculation
    // This would analyze movement patterns and identify sedentary periods
    return 480; // Placeholder: 8 hours
  }

  static Future<double> _calculateRestDayAdherence(DateTimeRange range) async {
    // TODO: Implement rest day adherence calculation
    // This would check if user is following planned rest days
    return 0.9; // Placeholder
  }
}
