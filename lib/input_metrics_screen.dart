import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

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

  final _mindfulness = ['Relaxation', 'Studying', 'Reading', 'Socialised'];

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

  @override
  Widget build(BuildContext ctx) {
    if (_busy) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_uid == null) return const Scaffold(body: Center(child: Text('User not logged in')));

    final fs     = Theme.of(ctx).textTheme.bodyMedium?.fontSize ?? 14.0;
    final accent = Theme.of(ctx).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Input Metrics',
            style: TextStyle(
                fontFamily: 'HappyMonkey',
                fontSize: fs,
                color: Theme.of(ctx).textTheme.bodyMedium?.color,
            )
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _card('Sleep', _slider(
            valueKey: 'sleep_quality_val',
            displayKey: 'sleep_quality',
            min: 0,
            max: 12,
            divisions: 12,
            toLabel: _sleepBucket,
            accent: accent,
            fontSize: fs,
          )),
          _card('Hydration', _slider(
            valueKey: 'hydration_val',
            displayKey: 'hydration',
            min: 0,
            max: 4,
            divisions: 8,
            toLabel: _hydrationBucket,
            accent: accent,
            fontSize: fs,
          )),
          _card('Exercise', _slider(
            valueKey: 'exercise_val',
            displayKey: 'exercise',
            min: 0,
            max: 120,
            divisions: 12,
            toLabel: _exerciseBucket,
            accent: accent,
            fontSize: fs,
          )),
          _card('Mood',       _moodRow(fs, accent)),
          _card('Mindfulness',_mindfulnessChips(fs, accent)),
          _card('Meal Times', _mealRows(fs), compact: true),
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
            inactiveTrackColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            thumbColor: accent,
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
        Text(
          _m[displayKey] ?? '—',
          style: TextStyle(fontSize: fontSize, color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
      ],
    );
  }

  Widget _moodRow(double fs, Color accent) {
    const moods = {'):': 'Sad', '|:': 'Neutral', '(:': 'Happy'};
    final sel   = _m['mindset'] as String?;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: moods.entries.map((e) {
        final chosen = e.value == sel;
        return GestureDetector(
          onTap: () => _save('mindset', chosen ? null : e.value),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: chosen ? accent : Colors.transparent,
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(e.key, style: TextStyle(fontSize: 24)),
          ),
        );
      }).toList(),
    );
  }

  Widget _mindfulnessChips(double fs, Color accent) {
    final sel = (_m['mindfulness_activities'] as List?)?.cast<String>() ?? <String>[];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _mindfulness.map((o) {
        final chosen = sel.contains(o);
        return ChoiceChip(
          label: Text(o, style: TextStyle(fontSize: fs)),
          selected: chosen,
          selectedColor: accent,
          onSelected: (_) {
            final list = List<String>.from(sel);
            chosen ? list.remove(o) : list.add(o);
            _save('mindfulness_activities', list);
          },
        );
      }).toList(),
    );
  }

  Widget _mealRows(double fs) => Column(children: [
    _mealRow('Breakfast','breakfast_time',fs),
    _mealRow('Lunch',     'lunch_time',    fs),
    _mealRow('Dinner',    'dinner_time',   fs),
  ]);

  Widget _mealRow(String lbl, String key, double fs) {
    final val = _m[key] as String?;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(lbl, style: TextStyle(fontSize: fs)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (val != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              splashRadius: 16,
              onPressed: () => _save(key, null),
            ),
          Text(val ?? '--:--', style: TextStyle(fontSize: fs)),
        ]),
        onTap: () async {
          final now  = TimeOfDay.now();
          final init = val == null
              ? now
              : TimeOfDay(hour: int.parse(val.split(':')[0]), minute: int.parse(val.split(':')[1]));
          final t    = await showTimePicker(context: context, initialTime: init);
          if (t != null) {
            final hh = t.hour.toString().padLeft(2, '0');
            final mm = t.minute.toString().padLeft(2, '0');
            _save(key, '$hh:$mm');
          }
        },
      ),
    );
  }

  Widget _card(String title, Widget child, {bool compact = false}) => Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: EdgeInsets.fromLTRB(10, compact ? 6 : 10, 10, compact ? 6 : 10),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2C2F36)
          : Colors.grey.shade200,
      border: Border.all(color: Colors.black, width: 1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    ),
  );
}