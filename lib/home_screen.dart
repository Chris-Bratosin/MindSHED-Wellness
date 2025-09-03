import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';

import 'activities_screen.dart';
import 'profile_screen.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';
import 'transition_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ====== DATA / STATE (unchanged) ======
  List<Map<String, dynamic>> tasks = [];
  Set<int> animatingTasks = {};
  int _selectedIndex = 2;

  final List<Color> taskColors = const [
    Color(0xFFB6FFB1),
    Color(0xFFFFDC75),
    Color(0xFFFFB173),
    Color(0xFFFF8A7D),
  ];

  final List<Map<String, dynamic>> dailyQuestPool = const [
    {'title': 'Drink 8 glasses of water', 'xp': 10},
    {'title': 'Take a 10-minute walk', 'xp': 15},
    {'title': 'Practice deep breathing for 5 minutes', 'xp': 25},
    {'title': 'Write in your journal', 'xp': 30},
    {'title': 'Stretch for 5 minutes', 'xp': 10},
    {'title': 'Disconnect from screens for 30 minutes', 'xp': 15},
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final sessionBox = await Hive.openBox('session');
    final taskBox = await Hive.openBox('userTasks');
    final questBox = await Hive.openBox('dailyQuests');
    final userId = sessionBox.get('loggedInUser') as String?;
    if (userId == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final completedKey = 'completedQuestsFor_${userId}_$today';
    final completed = List<String>.from(questBox.get(completedKey) ?? []);
    final lastUpdated = questBox.get('lastUpdatedFor_$userId');

    if (lastUpdated != today) {
      final random = Random();
      final shuffled = List<Map<String, dynamic>>.from(dailyQuestPool);
      shuffled.shuffle(random);
      final todayQuests = shuffled.take(4).map((q) => {
        'title': q['title'],
        'xp': q['xp'],
        'color': _getColorFromXP(q['xp']).r,
        'isQuest': true,
        'checked': false,
      }).toList();
      await questBox.put(userId, jsonEncode(todayQuests));
      await questBox.put('lastUpdatedFor_$userId', today);
    }

    final questData = questBox.get(userId);
    final manualData = taskBox.get(userId);

    final loadedQuests = questData != null
        ? List<Map<String, dynamic>>.from(
        (jsonDecode(questData) as List).map((e) => Map<String, dynamic>.from(e)))
        : <Map<String, dynamic>>[];

    final filtered = loadedQuests.where((q) => !completed.contains(q['title'])).toList();

    final loadedManual = manualData != null
        ? List<Map<String, dynamic>>.from(
        (jsonDecode(manualData) as List).map((e) => Map<String, dynamic>.from(e)))
        : <Map<String, dynamic>>[];

    setState(() {
      tasks = [...filtered, ...loadedManual].map((t) => {...t, 'checked': false}).toList();
    });
  }

  Color _getColorFromXP(int xp) {
    if (xp <= 10) return taskColors[0];
    if (xp <= 15) return taskColors[1];
    if (xp <= 25) return taskColors[2];
    return taskColors[3];
  }

  Future<void> _saveManualTasks() async {
    final sessionBox = await Hive.openBox('session');
    final userId = sessionBox.get('loggedInUser') as String?;
    if (userId == null) return;
    final taskBox = await Hive.openBox('userTasks');
    final manual = tasks.where((t) => t['isQuest'] != true).toList();
    await taskBox.put(userId, jsonEncode(manual));
  }

  void _completeTask(int index) async {
    if (animatingTasks.contains(index)) return;
    final sessionBox = await Hive.openBox('session');
    final questBox = await Hive.openBox('dailyQuests');
    final userId = sessionBox.get('loggedInUser') as String?;
    if (userId == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final task = tasks[index];
    if (task['isQuest'] == true) {
      final completedKey = 'completedQuestsFor_${userId}_$today';
      final completed = List<String>.from(questBox.get(completedKey) ?? []);
      completed.add(task['title']);
      await questBox.put(completedKey, completed.toSet().toList());

      final xpKey = '${userId}_totalXp';
      final gained = task['xp'] as int;
      final currentXp = sessionBox.get(xpKey) as int? ?? 0;
      await sessionBox.put(xpKey, currentXp + gained);
    }

    setState(() {
      tasks[index]['checked'] = true;
      animatingTasks.add(index);
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        tasks.removeAt(index);
        animatingTasks.remove(index);
      });
      _saveManualTasks();
    });
  }

  Future<void> _showAddTaskDialog() async {
    String newTitle = '';
    Color selectedColor = taskColors[0];

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Enter task name'),
                    onChanged: (v) => newTitle = v,
                  ),
                  const SizedBox(height: 20),
                  const Text('Select Color:'),
                  Wrap(
                    spacing: 8,
                    children: taskColors.map((c) {
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = c),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColor == c ? Colors.black : Colors.black26,
                              width: selectedColor == c ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (newTitle.trim().isNotEmpty) {
                      setState(() {
                        tasks.add({
                          'title': newTitle.trim(),
                          'color': selectedColor.r,
                          'isQuest': false,
                          'checked': false,
                        });
                      });
                      _saveManualTasks();
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ====== UI PIECES ======
  Widget _pillHeader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Text(
          'Home',
          style: TextStyle(
            fontFamily: 'HappyMonkey',
            fontWeight: FontWeight.w600,
            fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 18) + 4,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks yet. Add one!'));
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: tasks.length,
      itemBuilder: (ctx, i) {
        final task = tasks[i];
        final isQuest = task['isQuest'] == true;
        final isChecked = task['checked'] == true;
        final isAnim = animatingTasks.contains(i);

        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: isAnim ? 0 : 1,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Color(task['color']),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(2, 2)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['title'],
                          style: const TextStyle(
                            fontFamily: 'HappyMonkey',
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        if (isQuest && task.containsKey('xp'))
                          const SizedBox(height: 2),
                        if (isQuest && task.containsKey('xp'))
                          const Text(' ', style: TextStyle(fontSize: 2)), // keeps height consistent
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _completeTask(i),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: AnimatedOpacity(
                        opacity: isChecked ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(Icons.check, size: 18, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dailyTasksCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 4),
          const Text(
            'Daily Tasks',
            style: TextStyle(fontFamily: 'HappyMonkey', fontSize: 20, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          _buildTaskList(),
        ],
      ),
    );
  }

  // Square-ish buttons to match mock
  Widget _bottomNav() {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navItem(Icons.settings, 0, context),
            _navItem(Icons.auto_graph, 1, context),
            _navItem(Icons.home, 2, context), // Home highlighted
            _navItem(Icons.self_improvement, 3, context),
            _navItem(Icons.person, 4, context),
          ],
        ),
      ),
    );
  }

  // Rounded-square buttons inside the tray
  Widget _navItem(IconData icon, int idx, BuildContext context) {
    final isSel = _selectedIndex == idx;
    const mint = Color(0xFFB6FFB1);

    return Material(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() => _selectedIndex = idx);
          if (idx == 0) {
            Navigator.pushReplacement(context, createFadeRoute(const SettingsScreen()));
          } else if (idx == 1) {
            Navigator.pushReplacement(context, createFadeRoute(const InsightsScreen()));
          } else if (idx == 2) {
            Navigator.pushReplacement(context, createFadeRoute(const HomeScreen()));
          } else if (idx == 3) {
            Navigator.pushReplacement(context, createFadeRoute(const ActivitiesScreen()));
          } else if (idx == 4) {
            Navigator.pushReplacement(context, createFadeRoute(const ProfileScreen()));
          }
        },
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel ? mint : Colors.white, // mint when selected, white idle
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: isSel ? Colors.black : Colors.grey[800], size: 26),
        ),
      ),
    );
  }


  // ====== BUILD ======
  @override
  Widget build(BuildContext context) {
    // soft cream background like the mock
    const cream = Color(0xFFFFF9DA); // tweak if you want warmer/cooler
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            const SizedBox(height: 4),
            _pillHeader(),
            const SizedBox(height: 18),
            _dailyTasksCard(),
            const SizedBox(height: 18),
            Center(
              child: InkWell(
                onTap: _showAddTaskDialog,
                child: Material(
                  elevation: 3,
                  shape: const CircleBorder(side: BorderSide(color: Colors.black, width: 2)),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    child: const Icon(Icons.add, size: 30, color: Colors.black87),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Column(
                children: [
                  Text(
                    'Your journey to a\nbetter you starts here.',
                    style: TextStyle(fontSize: 16, fontFamily: 'HappyMonkey'),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Be yourself. Thrive.',
                    style: TextStyle(fontSize: 16, fontFamily: 'HappyMonkey'),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Find Peace in the\nPresent Moment.',
                    style: TextStyle(fontSize: 16, fontFamily: 'HappyMonkey'),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }
}
