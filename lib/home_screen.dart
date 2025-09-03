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
import 'shared_navigation.dart';
import 'shared_ui_components.dart';

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
      final todayQuests = shuffled
          .take(4)
          .map(
            (q) => {
              'title': q['title'],
              'xp': q['xp'],
              'color': _getColorFromXP(q['xp']).value,
              'isQuest': true,
              'checked': false,
            },
          )
          .toList();
      await questBox.put(userId, jsonEncode(todayQuests));
      await questBox.put('lastUpdatedFor_$userId', today);
    }

    final questData = questBox.get(userId);
    final manualData = taskBox.get(userId);

    final loadedQuests = questData != null
        ? List<Map<String, dynamic>>.from(
            (jsonDecode(questData) as List).map(
              (e) => _migrateTaskData(Map<String, dynamic>.from(e)),
            ),
          )
        : <Map<String, dynamic>>[];

    final filtered = loadedQuests
        .where((q) => !completed.contains(q['title']))
        .toList();

    final loadedManual = manualData != null
        ? List<Map<String, dynamic>>.from(
            (jsonDecode(manualData) as List).map(
              (e) => _migrateTaskData(Map<String, dynamic>.from(e)),
            ),
          )
        : <Map<String, dynamic>>[];

    setState(() {
      tasks = [
        ...filtered,
        ...loadedManual,
      ].map((t) => {...t, 'checked': false}).toList();
    });
  }

  Color _getColorFromXP(int xp) {
    if (xp <= 10) return taskColors[0];
    if (xp <= 15) return taskColors[1];
    if (xp <= 25) return taskColors[2];
    return taskColors[3];
  }

  Map<String, dynamic> _migrateTaskData(Map<String, dynamic> task) {
    // Check if color is stored as a double (old format) and convert to int
    if (task.containsKey('color') && task['color'] is double) {
      // If it's a double, it's likely the red component from the old format
      // We need to reconstruct the full color value
      double redComponent = task['color'] as double;

      // Find the matching color from taskColors based on the red component
      Color? matchingColor;
      for (Color color in taskColors) {
        if ((color.red / 255.0 - redComponent).abs() < 0.01) {
          matchingColor = color;
          break;
        }
      }

      // If we found a match, use its full value, otherwise use a default
      task['color'] = matchingColor?.value ?? taskColors[0].value;
    }

    return task;
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
                    decoration: const InputDecoration(
                      hintText: 'Enter task name',
                    ),
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
                              color: selectedColor == c
                                  ? Colors.black
                                  : Colors.black26,
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
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (newTitle.trim().isNotEmpty) {
                      setState(() {
                        tasks.add({
                          'title': newTitle.trim(),
                          'color': selectedColor.value,
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
    final fontSize =
        (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 18) + 4;
    return SharedUIComponents.buildHeaderPill('Home', fontSize: fontSize);
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

        return SharedUIComponents.buildTaskItem(
          title: task['title'],
          color: Color(task['color']),
          isChecked: isChecked,
          onTap: () => _completeTask(i),
          isAnimating: isAnim,
        );
      },
    );
  }

  Widget _dailyTasksCard() {
    return SharedUIComponents.buildCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      borderRadius: 22,
      child: Column(
        children: [
          const SizedBox(height: 4),
          const Text(
            'Daily Tasks',
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: 20,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          _buildTaskList(),
        ],
      ),
    );
  }

  // ====== BUILD ======
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SharedUIComponents.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            const SizedBox(height: 4),
            _pillHeader(),
            const SizedBox(height: 18),
            _dailyTasksCard(),
            const SizedBox(height: 18),
            SharedUIComponents.buildAddButton(_showAddTaskDialog),
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
      bottomNavigationBar: SharedNavigation.buildBottomNavigation(
        selectedIndex: _selectedIndex,
        context: context,
      ),
    );
  }
}
