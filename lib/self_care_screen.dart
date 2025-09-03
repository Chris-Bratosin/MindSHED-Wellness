import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'activities_screen.dart'; // for back fallback

class SelfCareScreen extends StatefulWidget {
  const SelfCareScreen({super.key});

  @override
  State<SelfCareScreen> createState() => _SelfCareScreenState();
}

class _SelfCareScreenState extends State<SelfCareScreen> {
  // ----- palette -----
  static const cream = Color(0xFFFFF9DA);
  static const mint = Color(0xFFB6FFB1);
  static const panelBlue = Color(0xFFE6F3FF);

  // ----- data you already have -----
  final Map<String, List<String>> selfCareTasks = {
    "Physical": [
      "Take a 5-minute stretch break",
      "Drink a full glass of water",
      "Take a 10-minute walk outside",
      "Do a quick bodyweight exercise",
      "Try a new yoga pose to relax",
    ],
    "Emotional": [
      "Write down three things you're grateful for",
      "Listen to your favorite song",
      "Call or text a loved one",
      "Practice deep breathing for 5 minutes",
      "Write in a journal",
    ],
    "Mental": [
      "Read 5 pages of a book",
      "Solve a small puzzle",
      "Practice mindfulness for 10 minutes",
      "Learn a new word and use it",
      "Write down a personal goal",
    ],
    "Social": [
      "Message a friend you haven't talked to in a while",
      "Join a community event",
      "Introduce yourself to someone new",
      "Have a meaningful conversation",
      "Do a random act of kindness",
    ],
  };

  // ----- state -----
  String selectedType = "Physical";
  String? _userId;

  /// simple completion map: { type: { taskText: bool } }
  final Map<String, Map<String, bool>> _completed = {
    "Physical": {},
    "Emotional": {},
    "Mental": {},
    "Social": {},
  };

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // load user id if available – optional
    final session = await Hive.openBox('session');
    _userId = session.get('loggedInUser');
    // ensure completion map contains all current tasks (defaults to false)
    for (final entry in selfCareTasks.entries) {
      _completed.putIfAbsent(entry.key, () => {});
      for (final task in entry.value) {
        _completed[entry.key]!.putIfAbsent(task, () => false);
      }
    }
    // try load saved state (optional; if you don’t want persistence, remove this block)
    if (_userId != null) {
      final box = await Hive.openBox('selfCareSimple');
      final raw = box.get('sc_$_userId');
      if (raw is Map) {
        for (final type in _completed.keys) {
          final m = raw[type];
          if (m is Map) {
            _completed[type]!.addAll(m.map((k, v) => MapEntry(k.toString(), v == true)));
          }
        }
      }
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (_userId == null) return;
    final box = await Hive.openBox('selfCareSimple');
    await box.put('sc_$_userId', _completed);
  }

  // ----- UI helpers -----
  Widget _pillHeader(String title) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
          title,
          style: const TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: 22,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _selectorCard() {
    Widget chip(String label) {
      final sel = selectedType == label;
      return Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => selectedType = label),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? mint : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'HappyMonkey',
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          const Text(
            'Select self-care type',
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              chip('Physical'),
              chip('Emotional'),
              chip('Mental'),
              chip('Social'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tasksPanel() {
    final tasks = selfCareTasks[selectedType] ?? const <String>[];

    return Container(
      decoration: BoxDecoration(
        color: panelBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        children: [
          // task list
          ...tasks.map((t) {
            final checked = _completed[selectedType]?[t] ?? false;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // checkbox look (custom to match mock)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _completed[selectedType]![t] = !checked;
                      });
                      _save();
                    },
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: checked ? Colors.black : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: checked
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(
                        fontFamily: 'HappyMonkey',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 18),

          // Generate button (visual only for now)
          Center(
            child: Material(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {},
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: mint,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Text(
                    'Generate random tasks',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'HappyMonkey',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ActivitiesScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            _pillHeader('Self Care'),
            const SizedBox(height: 16),
            _selectorCard(),
            const SizedBox(height: 12),
            _tasksPanel(),
            const SizedBox(height: 18),

            // Back button
            Center(
              child: Material(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _goBack,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: mint,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'HappyMonkey',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
