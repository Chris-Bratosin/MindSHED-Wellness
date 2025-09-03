import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'manual_entry_screen.dart';

class InputMetricsScreen extends StatefulWidget {
  const InputMetricsScreen({super.key});
  @override
  State<InputMetricsScreen> createState() => _InputMetricsScreenState();
}

class _InputMetricsScreenState extends State<InputMetricsScreen> {
  late Box _box, _session;
  String? _uid;
  late String _today;
  Map<String, dynamic> _m = {};
  bool _busy = true;

  final _mindfulness = [
    'Relaxation',
    'Studying',
    'Reading',
    'Socialised',
    'Meditation',
    'Exercise',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _session = await Hive.openBox('session');
    _box = await Hive.openBox('dailyMetrics');
    _uid = _session.get('loggedInUser');
    if (_uid == null) {
      setState(() => _busy = false);
      return;
    }
    _today = "${_uid}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}";
    _m = Map<String, dynamic>.from(_box.get(_today) ?? {});
    setState(() => _busy = false);
  }

  String _sleepBucket(double h) {
    if (h < 4) return '<4 hours';
    if (h < 6) return '4-6 hours';
    if (h < 10) return '7-9 hours';
    return '10+ hours';
  }

  String _hydrationBucket(double l) {
    if (l < 1.5) return '0-1.5 litres';
    if (l < 2.5) return '1.5-2.5 litres';
    if (l < 3.5) return '2.5-3.5 litres';
    return '3.5+ litres';
  }

  String _exerciseBucket(double m) {
    if (m < 10) return '0-10 minutes';
    if (m < 30) return '10-30 minutes';
    if (m < 60) return '30-60 minutes';
    return '60+ minutes';
  }

  void _save(String k, dynamic v) {
    setState(() => _m[k] = v);
    _box.put(_today, _m);
  }

  Widget _buildDataOptionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    double fontSize,
  ) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.black),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'HappyMonkey',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backButton() => Center(
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

  void _showManualEntryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManualEntryScreen()),
    );
  }

  void _showAppleHealthScreen() {
    // TODO: Navigate to Apple Health integration screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple Health Integration - Coming Soon!')),
    );
  }

  void _showGoogleFitScreen() {
    // TODO: Navigate to Google Fit integration screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Fit Integration - Coming Soon!')),
    );
  }

  void _showOuraRingScreen() {
    // TODO: Navigate to Oura Ring integration screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Oura Ring Integration - Coming Soon!')),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    if (_busy) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_uid == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    final fs = Theme.of(ctx).textTheme.bodyMedium?.fontSize ?? 16.0;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

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
                    'Input Data',
                    style: TextStyle(
                      fontFamily: 'HappyMonkey',
                      fontSize: fs + 4,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Data Input Options Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildDataOptionCard(
                      'Manual Entry',
                      Icons.edit_note,
                      const Color(0xFFE8F5E8), // Light green
                      () => _showManualEntryScreen(),
                      fs,
                    ),
                    _buildDataOptionCard(
                      'Apple Health',
                      Icons.health_and_safety,
                      const Color(0xFFE3F2FD), // Light blue
                      () => _showAppleHealthScreen(),
                      fs,
                    ),
                    _buildDataOptionCard(
                      'Google Fit',
                      Icons.fitness_center,
                      const Color(0xFFF3E5F5), // Light purple
                      () => _showGoogleFitScreen(),
                      fs,
                    ),
                    _buildDataOptionCard(
                      'Oura Ring',
                      Icons.favorite,
                      const Color(0xFFFFF3E0), // Light orange
                      () => _showOuraRingScreen(),
                      fs,
                    ),
                  ],
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

  Widget _buildMetricCard(
    String title,
    IconData icon,
    Color color,
    Widget child,
    double fs,
    bool isDark, {
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(compact ? 6 : 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2B30) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: fs,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _slider({
    required String valueKey,
    required String displayKey,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) toLabel,
    required Color accent,
    required double fontSize,
  }) {
    final v = (_m[valueKey] as double?) ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            activeTrackColor: accent,
            inactiveTrackColor: isDark
                ? Colors.grey.shade700
                : Colors.grey.shade300,
            thumbColor: accent,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
            valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
            valueIndicatorColor: accent,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Slider(
            value: v,
            min: min,
            max: max,
            divisions: divisions,
            label: v.toStringAsFixed(1),
            onChanged: (x) => setState(() => _m[valueKey] = x),
            onChangeEnd: (x) => _save(displayKey, toLabel(x)),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withOpacity(0.6)),
          ),
          child: Text(
            _m[displayKey] ?? '—',
            style: TextStyle(
              fontSize: fontSize - 1,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _moodRow(double fs, Color accent) {
    const moods = {'😢': 'Sad', '😐': 'Neutral', '😊': 'Happy'};
    final sel = _m['mindset'] as String?;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: moods.entries.map((e) {
        final chosen = e.value == sel;
        return GestureDetector(
          onTap: () => _save('mindset', chosen ? null : e.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: chosen ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: chosen ? accent : Colors.grey.shade400,
                width: 1,
              ),
              boxShadow: chosen
                  ? [
                      BoxShadow(
                        color: accent.withOpacity(0.3),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Text(e.key, style: TextStyle(fontSize: 20)),
          ),
        );
      }).toList(),
    );
  }

  Widget _mindfulnessChips(double fs, Color accent) {
    final sel =
        (_m['mindfulness_activities'] as List?)?.cast<String>() ?? <String>[];
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: _mindfulness.map((o) {
          final chosen = sel.contains(o);
          return GestureDetector(
            onTap: () {
              final list = List<String>.from(sel);
              chosen ? list.remove(o) : list.add(o);
              _save('mindfulness_activities', list);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: chosen ? accent.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: chosen
                      ? accent.withOpacity(0.6)
                      : Colors.grey.shade300,
                  width: chosen ? 1.5 : 1,
                ),
                boxShadow: chosen
                    ? [
                        BoxShadow(
                          color: accent.withOpacity(0.2),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                o,
                style: TextStyle(
                  fontSize: fs - 2,
                  fontWeight: chosen ? FontWeight.w600 : FontWeight.normal,
                  color: chosen
                      ? accent
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _mealRows(double fs) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _mealCircle(
        'Breakfast',
        'breakfast_time',
        fs,
        Icons.wb_sunny_rounded,
        Colors.orange,
      ),
      _mealCircle(
        'Lunch',
        'lunch_time',
        fs,
        Icons.wb_sunny_outlined,
        Colors.yellow.shade700,
      ),
      _mealCircle(
        'Dinner',
        'dinner_time',
        fs,
        Icons.nightlight_round,
        Colors.indigo,
      ),
    ],
  );

  Widget _mealCircle(
    String lbl,
    String key,
    double fs,
    IconData icon,
    Color color,
  ) {
    final val = _m[key] as String?;

    return GestureDetector(
      onTap: () async {
        final now = TimeOfDay.now();
        final init = val == null
            ? now
            : TimeOfDay(
                hour: int.parse(val.split(':')[0]),
                minute: int.parse(val.split(':')[1]),
              );
        final t = await showTimePicker(context: context, initialTime: init);
        if (t != null) {
          final hh = t.hour.toString().padLeft(2, '0');
          final mm = t.minute.toString().padLeft(2, '0');
          _save(key, '$hh:$mm');
        }
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              val ?? lbl,
              style: TextStyle(
                fontSize: val != null ? fs - 2 : fs - 1,
                fontWeight: FontWeight.w600,
                color: val != null
                    ? color
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            if (val != null) ...[
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () => _save(key, null),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 12,
                    color: Colors.red.shade600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
