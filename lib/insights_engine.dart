import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:mindshed_app/wellness_predictor.dart';

enum Grade { red, amber, green }
enum DateRange { daily, weekly, monthly }

class InsightsEngine {
  final Box _metricsBox;
  final WellnessPredictor _predictor = WellnessPredictor();
  bool _isPredictorInitialized = false;

  // Define standard feature names to ensure consistency
  static const String SLEEP_FEATURE = 'sleep_bucket';
  static const String EXERCISE_FEATURE = 'exercise_bucket';
  static const String HYDRATION_FEATURE = 'hydration_bucket';
  static const String MINDSET_FEATURE = 'mindset';
  static const String MINDFULNESS_FEATURE = 'mindfulness_count';
  static const String BREAKFAST_FEATURE = 'breakfast_time';
  static const String LUNCH_FEATURE = 'lunch_time';
  static const String DINNER_FEATURE = 'dinner_time';

  InsightsEngine(this._metricsBox);

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

  Future<void> initPredictor() async => _ensurePredictor();
  
  void dispose() {
    if (_isPredictorInitialized) {
      _predictor.close();
      _isPredictorInitialized = false;
    }
  }

  Map<String, dynamic> _maskMealsByClock(Map<String, dynamic> f) {
    try {
      final now = DateTime.now();
      final mins = now.hour * 60 + now.minute;
      const bfEnd    = 10 * 60 + 30;  // 10:30 AM
      const lunchEnd = 15 * 60;       // 3:00 PM
      const dinEnd   = 21 * 60;       // 9:00 PM
      const neutral  = '00:00';
      
      // Only add placeholders for meals that should have occurred by now
      if (mins >= bfEnd && f[BREAKFAST_FEATURE] == null) f[BREAKFAST_FEATURE] = neutral;
      if (mins >= lunchEnd && f[LUNCH_FEATURE] == null) f[LUNCH_FEATURE] = neutral;
      if (mins >= dinEnd && f[DINNER_FEATURE] == null) f[DINNER_FEATURE] = neutral;
      
      return f;
    } catch (e) {
      print('Error in _maskMealsByClock: $e');
      return f; // Return original map on error
    }
  }

  Map<String, dynamic> _pluckFeatures(Map<String, dynamic> raw) {
    try {
      return {
        SLEEP_FEATURE: raw[SLEEP_FEATURE] as String? ?? 
                       raw['sleep_quality'] as String? ?? '',
        
        EXERCISE_FEATURE: raw[EXERCISE_FEATURE] as String? ?? 
                         raw['exercise'] as String? ?? '',
        
        HYDRATION_FEATURE: raw[HYDRATION_FEATURE] as String? ?? 
                          raw['hydration'] as String? ?? '',
        
        MINDSET_FEATURE: raw[MINDSET_FEATURE] as String? ?? '',
        
        MINDFULNESS_FEATURE: (raw['mindfulness_activities'] as List?)?.length ?? 0,
        
        BREAKFAST_FEATURE: raw[BREAKFAST_FEATURE] as String? ?? '',
        LUNCH_FEATURE: raw[LUNCH_FEATURE] as String? ?? '',
        DINNER_FEATURE: raw[DINNER_FEATURE] as String? ?? '',
      };
    } catch (e) {
      print('Error extracting features: $e');
      // Return empty map with expected structure
      return {
        SLEEP_FEATURE: '',
        EXERCISE_FEATURE: '',
        HYDRATION_FEATURE: '',
        MINDSET_FEATURE: '',
        MINDFULNESS_FEATURE: 0,
        BREAKFAST_FEATURE: '',
        LUNCH_FEATURE: '',
        DINNER_FEATURE: '',
      };
    }
  }

  Future<int> getPredictedScore(String userId, DateRange range) async {
    if (userId.isEmpty) {
      print('Error: Empty user ID provided');
      return 0;
    }
    
    try {
      await _ensurePredictor();
      final dates = _getDatesForRange(range);
      double total = 0;
      int count = 0;

      for (final d in dates) {
        final raw = _metricsBox.get('${userId}_$d');
        if (raw is Map) {
          final feats = _pluckFeatures(_maskMealsByClock(Map<String, dynamic>.from(raw)));
          total += _predictor.score(feats);
          count++;
        }
      }
      
      if (count == 0) return 0;
      return (total / count).round();
    } catch (e) {
      print('Error calculating predicted score: $e');
      return 0;
    }
  }

  Future<Map<String, Grade>> getCategoryGrades(String userId, DateRange range) async {
    if (userId.isEmpty) {
      print('Error: Empty user ID provided');
      return {};
    }
    
    try {
      final dates = _getDatesForRange(range);
      final catScores = <String, List<int>>{};

      for (final d in dates) {
        final data = _metricsBox.get('${userId}_$d');
        if (data is! Map) continue;
        
        final map = Map<String, dynamic>.from(data);
        final dietTimes = <String>[];

        map.forEach((k, raw) {
          if (raw == null) return;
          if (raw is Iterable && raw.isEmpty) return;
          if (k.endsWith('_val') || k == 'mindset') return;

          // Handle meal times
          if (k == BREAKFAST_FEATURE || k == LUNCH_FEATURE || k == DINNER_FEATURE) {
            if (raw is String && raw.isNotEmpty) dietTimes.add(k);
            return;
          }

          // Handle hydration with exercise context
          if (k == HYDRATION_FEATURE || k == 'hydration') {
            final exerciseData = map[EXERCISE_FEATURE] as String? ?? 
                                map['exercise'] as String? ?? '';
            final score = _gradeHydration(
              raw.toString(),
              exerciseData,
            );
            catScores.putIfAbsent('hydration', () => []).add(score);
            return;
          }

          // Handle other categories
          final vals = raw is Iterable ? List<String>.from(raw) : [raw.toString()];
          final score = _gradeCategory(k.toLowerCase(), vals);
          catScores.putIfAbsent(k, () => []).add(score);
        });

        // Handle diet only if times are available
        if (dietTimes.isNotEmpty) {
          final dscore = _gradeDiet(dietTimes);
          catScores.putIfAbsent('diet', () => []).add(dscore);
        }
      }

      // Calculate average scores and convert to grades
      return catScores.map((cat, list) {
        if (list.isEmpty) return MapEntry(cat.toLowerCase(), Grade.red);
        final avg = list.reduce((a, b) => a + b) / list.length;
        return MapEntry(cat.toLowerCase(), _scoreToGrade(avg));
      });
    } catch (e) {
      print('Error calculating category grades: $e');
      return {};
    }
  }

  List<String> _getDatesForRange(DateRange r) {
    try {
      final now = DateTime.now(), fmt = DateFormat('yyyy-MM-dd');
      final len = r == DateRange.daily
          ? 1
          : r == DateRange.weekly
              ? 7
              : 30;
      
      // Generate dates excluding today if no data would be available yet
      return List.generate(len, (i) {
        final date = now.subtract(Duration(days: i));
        return fmt.format(date);
      });
    } catch (e) {
      print('Error generating dates: $e');
      // Return just today's date as fallback
      return [DateFormat('yyyy-MM-dd').format(DateTime.now())];
    }
  }

  int _gradeCategory(String key, List<String> vals) {
    if (vals.isEmpty) return 1;
    
    try {
      switch (key) {
        case 'sleep_bucket':
        case 'sleep_quality':
          if (vals.contains('7-9 hours')) return 3;
          if (vals.contains('4-6 hours') || vals.contains('10+ hours')) return 2;
          return 1;

        case 'exercise_bucket':
        case 'exercise':
          if (vals.contains('30-60 minutes') || vals.contains('60+ minutes')) return 3;
          if (vals.contains('10-30 minutes')) return 2;
          return 1;

        case 'mindfulness_activities':
          final n = vals.length;
          if (n >= 2) return 3;
          if (n == 1) return 2;
          return 1;

        default:
          return 2; // Neutral default
      }
    } catch (e) {
      print('Error grading category $key: $e');
      return 1; // Safe default
    }
  }

  int _gradeDiet(List<String> mealTimes) {
    try {
      final now = DateTime.now();
      final mins = now.hour * 60 + now.minute;
      
      // Adjust expected meal count based on time of day
      int expectedMeals;
      if (mins < 10 * 60 + 30) { // Before 10:30 AM
        expectedMeals = 0; // Only expect previous day's meals
      } else if (mins < 15 * 60) { // Before 3 PM
        expectedMeals = 1; // Expect breakfast
      } else if (mins < 21 * 60) { // Before 9 PM
        expectedMeals = 2; // Expect breakfast and lunch
      } else {
        expectedMeals = 3; // Expect all three meals
      }
      
      final actualMeals = mealTimes.length;
      
      if (actualMeals >= expectedMeals) return 3;
      if (expectedMeals - actualMeals == 1) return 2;
      return 1;
    } catch (e) {
      print('Error grading diet: $e');
      return 1; // Safe default
    }
  }

  int _gradeHydration(String bucket, String exBucket) {
    try {
      final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(bucket);
      final rawValue = match?.group(0) ?? '0';
      final drank = double.tryParse(rawValue) ?? 0.0;
      final drankRounded = double.parse(drank.toStringAsFixed(1));

      // Determine if high-intensity exercise was performed
      final highIntensity = exBucket.contains('60+ minutes') || 
                           exBucket.contains('30-60 minutes');
      
      // Adjust hydration targets based on exercise level
      if (highIntensity) {
        // Higher hydration targets for people exercising intensely
        if (drankRounded < 2.5) return 1; // Not enough hydration
        if (drankRounded >= 3.5) return 3; // Excellent hydration
        return 2; // Adequate hydration
      } else {
        // Standard hydration targets
        if (drankRounded < 1.5) return 1; // Not enough hydration
        if (drankRounded >= 2.5) return 3; // Excellent hydration
        return 2; // Adequate hydration
      }
    } catch (e) {
      print('Error grading hydration: $e');
      return 1; // Safe default
    }
  }

  Grade _scoreToGrade(double s) {
    if (s < 0 || s.isNaN) return Grade.red; // Handle invalid scores
    return s >= 2.5 ? Grade.green : s >= 1.5 ? Grade.amber : Grade.red;
  }
}