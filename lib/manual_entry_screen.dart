import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'health_data_models.dart';
import 'wellness_scoring_engine.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  late Box _session;
  String? _uid;
  bool _busy = true;
  bool _saving = false;

  // Form controllers
  final _stepsController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _sleepHoursController = TextEditingController();
  final _sleepMinutesController = TextEditingController();
  final _activeMinutesController = TextEditingController();
  final _hydrationController = TextEditingController();
  final _ageController = TextEditingController();

  // Form values
  double _sleepEfficiency = 0.8;
  double _weeklyConsistency = 0.7;
  double _restDayAdherence = 0.8;
  double _socialInteractionScore = 0.6;
  double _supportNetworkScore = 0.7;

  // Mindfulness activities
  final List<String> _availableActivities = [
    'Relaxation',
    'Studying',
    'Reading',
    'Socialised',
    'Meditation',
    'Exercise',
    'Yoga',
    'Walking',
    'Gym',
    'Swimming',
  ];
  final Set<String> _selectedActivities = <String>{};

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _stepsController.dispose();
    _heartRateController.dispose();
    _sleepHoursController.dispose();
    _sleepMinutesController.dispose();
    _activeMinutesController.dispose();
    _hydrationController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _session = await Hive.openBox('session');
    _uid = _session.get('loggedInUser');
    if (_uid == null) {
      setState(() => _busy = false);
      return;
    }

    // Set default age if available
    final userAge = _session.get('userAge');
    if (userAge != null) {
      _ageController.text = userAge.toString();
    }

    setState(() => _busy = false);
  }

  Future<void> _saveData() async {
    if (_uid == null) return;

    setState(() => _saving = true);

    try {
      // Create UnifiedHealthData from manual entry
      final healthData = UnifiedHealthData(
        steps: int.tryParse(_stepsController.text) ?? 0,
        heartRate: double.tryParse(_heartRateController.text),
        hrv: null, // Manual entry doesn't provide HRV
        sleep: _createSleepData(),
        exercises: null, // Manual entry doesn't track exercise sessions
        caloriesBurned: null,
        source: DataSource.manualEntry,
        quality: DataQuality.minimal,
        age: int.tryParse(_ageController.text) ?? 30,
        recoveryScore: null, // Manual entry doesn't provide recovery scores
        activeMinutes: int.tryParse(_activeMinutesController.text) ?? 0,
        exerciseSessions:
            _selectedActivities.contains('Exercise') ||
                _selectedActivities.contains('Gym') ||
                _selectedActivities.contains('Swimming')
            ? 1
            : 0,
        weeklyActivityConsistency: _weeklyConsistency,
        sedentaryMinutes: 480, // Default 8 hours sedentary
        restDayAdherence: _restDayAdherence,
        socialInteractionScore: _socialInteractionScore,
        supportNetworkScore: _supportNetworkScore,
      );

      // Calculate wellness score using new engine
      final engine = WellnessScoringEngine();
      final wellnessScore = engine.calculateOverallWellness(healthData);
      final category = engine.categorizeWellness(wellnessScore);
      final insight = engine.getWellnessInsight(wellnessScore, category);

      // Save to Hive with new format
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final key = '${_uid}_$today';

      final dataBox = await Hive.openBox('dailyMetrics');
      await dataBox.put(key, {
        'wellness_score': wellnessScore,
        'wellness_category': category.toString(),
        'wellness_insight': insight,
        'data_source': 'manual_entry',
        'data_quality': 'minimal',
        'timestamp': DateTime.now().toIso8601String(),
        'unified_data': {
          'steps': healthData.steps,
          'heart_rate': healthData.heartRate,
          'active_minutes': healthData.activeMinutes,
          'sleep_hours': _sleepHoursController.text.isNotEmpty
              ? int.tryParse(_sleepHoursController.text)
              : null,
          'sleep_minutes': _sleepMinutesController.text.isNotEmpty
              ? int.tryParse(_sleepMinutesController.text)
              : null,
          'sleep_efficiency': _sleepEfficiency,
          'hydration_litres': double.tryParse(_hydrationController.text),
          'mindfulness_activities': _selectedActivities.toList(),
          'weekly_consistency': _weeklyConsistency,
          'rest_day_adherence': _restDayAdherence,
          'social_interaction_score': _socialInteractionScore,
          'support_network_score': _supportNetworkScore,
          'age': healthData.age,
        },
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data saved! Wellness Score: ${wellnessScore.toStringAsFixed(1)}%',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving data. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  SleepData? _createSleepData() {
    final hours = int.tryParse(_sleepHoursController.text);
    final minutes = int.tryParse(_sleepMinutesController.text);

    if (hours == null && minutes == null) return null;

    final totalMinutes = (hours ?? 0) * 60 + (minutes ?? 0);
    if (totalMinutes == 0) return null;

    return SleepData(
      totalSleep: Duration(minutes: totalMinutes),
      sleepEfficiency: _sleepEfficiency,
      deepSleepPercentage: null, // Manual entry doesn't provide this
      remSleepPercentage: null, // Manual entry doesn't provide this
      lightSleepPercentage: null, // Manual entry doesn't provide this
      sleepLatency: Duration(minutes: 15), // Default estimate
      wakeAfterSleepOnset: 0, // Default
      scheduleConsistency: _weeklyConsistency,
      environmentScore: 0.8, // Default
      preSleepRoutineScore: 0.7, // Default
    );
  }

  Widget _buildMetricInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType ?? TextInputType.number,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: Icon(icon, color: Colors.black54),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderInput({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
    int? divisions,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ${(value * 100).round()}%',
            style: const TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            onChanged: onChanged,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: const Color(0xFFB6FFB1),
            inactiveColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildMindfulnessSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mindfulness Activities',
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableActivities.map((activity) {
                  final isSelected = _selectedActivities.contains(activity);
                  return FilterChip(
                    label: Text(activity),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedActivities.add(activity);
                        } else {
                          _selectedActivities.remove(activity);
                        }
                      });
                    },
                    selectedColor: const Color(0xFFB6FFB1),
                    checkmarkColor: Colors.black,
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      fontFamily: 'HappyMonkey',
                      color: isSelected ? Colors.black : Colors.black87,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton() {
    return Center(
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 120,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFB6FFB1),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Back',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'HappyMonkey',
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF9DA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_uid == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF9DA),
        body: Center(child: Text('User not logged in')),
      );
    }

    final fs = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9DA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    'Manual Entry',
                    style: TextStyle(
                      fontFamily: 'HappyMonkey',
                      fontSize: fs + 4,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildMetricInput(
                        label: 'Steps',
                        controller: _stepsController,
                        icon: Icons.directions_walk,
                        hint: 'Enter daily steps',
                      ),

                      _buildMetricInput(
                        label: 'Heart Rate (bpm)',
                        controller: _heartRateController,
                        icon: Icons.favorite,
                        hint: 'Enter resting heart rate',
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricInput(
                              label: 'Sleep Hours',
                              controller: _sleepHoursController,
                              icon: Icons.bedtime,
                              hint: 'Hours',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMetricInput(
                              label: 'Sleep Minutes',
                              controller: _sleepMinutesController,
                              icon: Icons.bedtime,
                              hint: 'Minutes',
                            ),
                          ),
                        ],
                      ),

                      _buildMetricInput(
                        label: 'Active Minutes',
                        controller: _activeMinutesController,
                        icon: Icons.fitness_center,
                        hint: 'Enter active minutes',
                      ),

                      _buildMetricInput(
                        label: 'Hydration (litres)',
                        controller: _hydrationController,
                        icon: Icons.water_drop,
                        hint: 'Enter water intake',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),

                      _buildMetricInput(
                        label: 'Age',
                        controller: _ageController,
                        icon: Icons.person,
                        hint: 'Enter your age',
                      ),

                      _buildMindfulnessSection(),

                      _buildSliderInput(
                        label: 'Sleep Efficiency',
                        value: _sleepEfficiency,
                        onChanged: (value) =>
                            setState(() => _sleepEfficiency = value),
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                      ),

                      _buildSliderInput(
                        label: 'Weekly Consistency',
                        value: _weeklyConsistency,
                        onChanged: (value) =>
                            setState(() => _weeklyConsistency = value),
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                      ),

                      _buildSliderInput(
                        label: 'Rest Day Adherence',
                        value: _restDayAdherence,
                        onChanged: (value) =>
                            setState(() => _restDayAdherence = value),
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                      ),

                      _buildSliderInput(
                        label: 'Social Interaction',
                        value: _socialInteractionScore,
                        onChanged: (value) =>
                            setState(() => _socialInteractionScore = value),
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                      ),

                      _buildSliderInput(
                        label: 'Support Network',
                        value: _supportNetworkScore,
                        onChanged: (value) =>
                            setState(() => _supportNetworkScore = value),
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                      ),

                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB6FFB1),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                color: Colors.black,
                                width: 2,
                              ),
                            ),
                            elevation: 4,
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Save Data',
                                  style: TextStyle(
                                    fontFamily: 'HappyMonkey',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _backButton(),
            ],
          ),
        ),
      ),
    );
  }
}
