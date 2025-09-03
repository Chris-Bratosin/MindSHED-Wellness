import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  // ----- palette -----
  static const cream = Color(0xFFFFF9DA);
  static const sage  = Color(0xFFD4E7C5);
  static const sageDark = Color(0xFFBFD5AA);
  static const mint  = Color(0xFFB6FFB1);

  // form
  final TextEditingController _goalName = TextEditingController();
  final TextEditingController _goalDesc = TextEditingController();
  DateTime? _dueDate;

  // storage
  late Box _sessionBox;
  late Box _goalBox;
  String? _userId;

  // state
  bool _viewMode = false; // false = Make Goal page, true = View Goals page
  List<Map<String, dynamic>> _goals = [];

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    _sessionBox = await Hive.openBox('session');
    _goalBox = await Hive.openBox('userGoals');
    _userId = _sessionBox.get('loggedInUser') as String?;
    if (_userId != null) _loadGoals();
  }

  // ---------- CRUD ----------
  Future<void> _saveGoals() async {
    if (_userId == null) return;
    await _goalBox.put(_userId, _goals);
  }

  void _loadGoals() {
    final stored = _goalBox.get(_userId);
    if (stored is List) {
      setState(() {
        // allow old entries without date
        _goals = stored.map<Map<String, dynamic>>((e) {
          final m = Map<String, dynamic>.from(e as Map);
          if (!m.containsKey('dueDate')) m['dueDate'] = null;
          return m;
        }).toList();
      });
    }
  }

  void _addGoal() async {
    final title = _goalName.text.trim();
    final desc  = _goalDesc.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      _toast('Please enter a goal name and description.');
      return;
    }
    setState(() {
      _goals.insert(0, {
        'title': title,
        'description': desc,
        'dueDate': _dueDate?.millisecondsSinceEpoch, // nullable
      });
      _goalName.clear();
      _goalDesc.clear();
      _dueDate = null;
    });
    await _saveGoals();
    _toast('Goal added!');
  }

  void _removeGoal(int index) async {
    setState(() => _goals.removeAt(index));
    await _saveGoals();
  }

  // ---------- helpers ----------
  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'HappyMonkey')))
    );
  }

  InputDecoration _pillInput(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'HappyMonkey'),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
    );
  }

  BoxDecoration _cardBox() => BoxDecoration(
    color: sage,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Colors.black, width: 1.8),
  );

  Widget _headerPill(String text) => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3))
        ],
      ),
      child: Text(text,
          style: const TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: 22,
              color: Colors.black)),
    ),
  );

  Widget _mintBtn(String label, VoidCallback onTap,
      {IconData? icon, EdgeInsetsGeometry? pad}) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: pad ?? const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: mint,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.black),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: const TextStyle(
                      fontFamily: 'HappyMonkey',
                      fontWeight: FontWeight.w700,
                      color: Colors.black)),
            ],
          ),
        ),
      ),
    );
  }

  // -------- Random goal generator --------
  void _generateGoal() {
    const templates = [
      {
        'title': 'Stay consistent in the gym for 1 month',
        'desc':
        'Go to the gym at least 3x per week for a month. Track workouts and set reminders.'
      },
      {
        'title': 'Read 2 books this month',
        'desc':
        'Finish two books by reading 20–30 minutes daily. Log progress each night.'
      },
      {
        'title': 'Improve sleep routine',
        'desc':
        'Aim for 7–8 hours nightly. No screens 30 minutes before bed; lights out by 11pm.'
      },
      {
        'title': 'Daily hydration habit',
        'desc':
        'Drink 2L water daily. Keep a bottle nearby and tick off four 500ml fills.'
      },
      {
        'title': 'Mindfulness streak: 10 minutes/day',
        'desc':
        'Meditate 10 minutes each day for two weeks. Use a timer and note how you feel.'
      },
    ];
    final pick = templates[Random().nextInt(templates.length)];
    setState(() {
      _goalName.text = pick['title']!;
      _goalDesc.text = pick['desc']!;
      _dueDate = DateTime.now().add(Duration(days: 28 + Random().nextInt(14)));
    });
  }

  // -------- dialogs --------
  void _showGoalDialog(Map<String, dynamic> goal, int index) {
    final due = goal['dueDate'] is int
        ? DateTime.fromMillisecondsSinceEpoch(goal['dueDate'] as int)
        : null;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: sage,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // title pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Text(
                  goal['title'] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'HappyMonkey',
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
              // description block
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Text(
                  goal['description'] ?? '',
                  style: const TextStyle(fontFamily: 'HappyMonkey'),
                ),
              ),
              const SizedBox(height: 12),
              // date pill
              if (due != null)
                _mintBtn(
                  'Due ${_fmtDate(due)}',
                      () {},
                  pad: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                )
              else
                _mintBtn('No due date', () {},
                    pad: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _mintBtn('Close', () => Navigator.pop(context)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _mintBtn('Mark Complete', () {
                      Navigator.pop(context);
                      _removeGoal(index);
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------- UI --------
  @override
  Widget build(BuildContext context) {
    final fs = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16.0;

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cream,
        centerTitle: true,
        leading: BackButton(color: Colors.black),
        title: Text('Goals',
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: fs,
              color: Colors.black,
            )),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          children: [
            _headerPill('Goals'),
            const SizedBox(height: 12),
            if (!_viewMode) ...[
              _buildMakeGoal(fs),
              const SizedBox(height: 12),
              _buildGenerator(fs),
              const SizedBox(height: 10),
              _mintBtn('View Goals', () => setState(() => _viewMode = true)),
              const SizedBox(height: 8),
              _mintBtn('Back', () => Navigator.maybePop(context)),
            ] else ...[
              _buildViewGoals(fs),
              const SizedBox(height: 10),
              _mintBtn('Back', () => setState(() => _viewMode = false)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMakeGoal(double fs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text('Make a personal goal',
                style: TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: fs,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _goalName,
            decoration: _pillInput('Goal Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _goalDesc,
            maxLines: 4,
            decoration: _pillInput('Describe your goal !'),
          ),
          const SizedBox(height: 12),
          // calendar selector block
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Column(
              children: [
                Text('When would you like to complete this by?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'HappyMonkey')),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month, size: 48, color: Colors.black),
                ),
                if (_dueDate != null)
                  Text('Selected: ${_fmtDate(_dueDate!)}',
                      style: const TextStyle(fontFamily: 'HappyMonkey')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _mintBtn('Confirm', _addGoal),
        ],
      ),
    );
  }

  Widget _buildGenerator(double fs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardBox().copyWith(color: sageDark),
      child: Column(
        children: [
          Text(
            'If you are struggling to create a goal,\ntry generating a random one!',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'HappyMonkey', fontSize: fs * 0.95),
          ),
          const SizedBox(height: 10),
          _mintBtn('Generate Goal', _generateGoal, icon: Icons.auto_awesome),
        ],
      ),
    );
  }

  Widget _buildViewGoals(double fs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardBox(),
      child: Column(
        children: [
          Center(
            child: Text('View Goals',
                style: TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: fs,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          if (_goals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                "It looks like you don’t have any goals yet.",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'HappyMonkey', fontSize: fs),
              ),
            )
          else
            ..._goals.asMap().entries.map((e) {
              final i = e.key;
              final g = e.value;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFFFD5),
                  border: Border.all(color: Colors.black, width: 1.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showGoalDialog(g, i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Text(
                      g['title'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: 'HappyMonkey',
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // date utils
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final res = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 0)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        // light border theming to fit app
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (res != null) setState(() => _dueDate = res);
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  @override
  void dispose() {
    _goalName.dispose();
    _goalDesc.dispose();
    super.dispose();
  }
}
