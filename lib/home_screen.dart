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
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> tasks = [];
  Set<int> animatingTasks = {};
  int _selectedIndex = 2;

  final List<Color> taskColors = [
    const Color(0xFFB6FFB1),
    const Color(0xFFFFDC75),
    const Color(0xFFFFB173),
    const Color(0xFFFF8A7D),
  ];

  final List<Map<String, dynamic>> dailyQuestPool = [
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
          .map((q) => {
                'title': q['title'],
                'xp': q['xp'],
                'color': _getColorFromXP(q['xp']).value,
                'isQuest': true,
                'checked': false,
              })
          .toList();
      await questBox.put(userId, jsonEncode(todayQuests));
      await questBox.put('lastUpdatedFor_$userId', today);
    }

    final questData = questBox.get(userId);
    final manualData = taskBox.get(userId);

    final loadedQuests = questData != null
        ? List<Map<String, dynamic>>.from((jsonDecode(questData) as List)
            .map((e) => Map<String, dynamic>.from(e)))
        : <Map<String, dynamic>>[];

    final filtered =
        loadedQuests.where((q) => !completed.contains(q['title'])).toList();

    final loadedManual = manualData != null
        ? List<Map<String, dynamic>>.from((jsonDecode(manualData) as List)
            .map((e) => Map<String, dynamic>.from(e)))
        : <Map<String, dynamic>>[];

    setState(() {
      tasks = [...filtered, ...loadedManual]
          .map((t) => {...t, 'checked': false})
          .toList();
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
                    decoration:
                        const InputDecoration(hintText: 'Enter task name'),
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
                            border: selectedColor == c
                                ? Border.all(color: Colors.black, width: 3)
                                : Border.all(color: Colors.black26),
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
                    child: const Text('Cancel')),
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

  Widget _buildTaskList() {
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks yet. Add one!'));
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
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
            child: GestureDetector(
              onLongPress: () => isQuest ? null : null,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(task['color']),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 3,
                        offset: const Offset(2, 2))
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task['title'],
                              style: const TextStyle(
                                  fontFamily: 'HappyMonkey',
                                  fontSize: 16,
                                  color: Colors.black)),
                          if (isQuest && task.containsKey('xp'))
                            Text('${task['xp']} XP',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.indigo)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _completeTask(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(5)),
                        child: AnimatedOpacity(
                            opacity: isChecked ? 1 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(Icons.check,
                                size: 16, color: Colors.black)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Home',
            style: TextStyle(
                fontFamily: 'HappyMonkey',
                fontSize:
                    (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 18) +
                        6,
                color: Theme.of(context).textTheme.bodyMedium?.color)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment,
                  size: 24,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height:
                      360, // Height for 4 tasks with extra space (4.5 * 80px per task)
                  child: _buildTaskList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
              child: InkWell(
                  onTap: _showAddTaskDialog,
                  child: Material(
                      elevation: 3,
                      shape: const CircleBorder(
                          side: BorderSide(color: Colors.black)),
                      child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Colors.white),
                          child: const Icon(Icons.add,
                              size: 30, color: Colors.black87))))),
          const SizedBox(height: 20),
          Center(
              child: Column(children: const [
            Text('Your journey to a\nbetter you starts here.',
                style: TextStyle(fontSize: 16, fontFamily: 'HappyMonkey'),
                textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text('Be yourself. Thrive.',
                style: TextStyle(fontSize: 16, fontFamily: 'HappyMonkey'),
                textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text('Find Peace in the\nPresent Moment.',
                style: TextStyle(fontSize: 16, fontFamily: 'HappyMonkey'),
                textAlign: TextAlign.center)
          ])),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
            ]),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _navItem(Icons.settings, 0, context),
          _navItem(Icons.auto_graph, 1, context),
          _navItem(Icons.home, 2, context),
          _navItem(Icons.self_improvement, 3, context),
          _navItem(Icons.person, 4, context),
        ]),
      ),
    );
  }

  Widget _navItem(IconData icon, int idx, BuildContext context) {
    final isSel = _selectedIndex == idx;
    final fill = isSel
        ? (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF40D404)
            : const Color(0xFFB6FFB1))
        : Theme.of(context).colorScheme.surface;
    final col = isSel ? Colors.black : Colors.grey[700];
    return Material(
      elevation: 3,
      shape: const CircleBorder(side: BorderSide(color: Colors.black)),
      child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            setState(() => _selectedIndex = idx);
            if (idx == 0)
              Navigator.pushReplacement(
                  context, createFadeRoute(const SettingsScreen()));
            if (idx == 1)
              Navigator.pushReplacement(
                  context, createFadeRoute(const InsightsScreen()));
            if (idx == 2)
              Navigator.pushReplacement(
                  context, createFadeRoute(const HomeScreen()));
            if (idx == 3)
              Navigator.pushReplacement(
                  context, createFadeRoute(const ActivitiesScreen()));
            if (idx == 4)
              Navigator.pushReplacement(
                  context, createFadeRoute(const ProfileScreen()));
          },
          child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(shape: BoxShape.circle, color: fill),
              child: Icon(icon, color: col))),
    );
  }
}
