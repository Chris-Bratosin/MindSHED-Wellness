import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:hive/hive.dart';

class SelfCareScreen extends StatefulWidget {
  const SelfCareScreen({Key? key}) : super(key: key);

  @override
  State<SelfCareScreen> createState() => _SelfCareScreenState();
}

class _SelfCareScreenState extends State<SelfCareScreen> {
  String selectedType = "Physical";
  String? _userId;

  Map<String, List<String>> selfCareTasks = {
    "Physical": [
      "Take a 5-minute stretch break",
      "Drink a full glass of water",
      "Take a 10-minute walk outside",
      "Do a quick bodyweight exercise",
      "Try a new yoga pose to relax"
    ],
    "Emotional": [
      "Write down three things you're grateful for",
      "Listen to your favorite song",
      "Call or text a loved one",
      "Practice deep breathing for 5 minutes",
      "Write in a journal"
    ],
    "Mental": [
      "Read 5 pages of a book",
      "Solve a small puzzle",
      "Practice mindfulness for 10 minutes",
      "Learn a new word and use it",
      "Write down a personal goal"
    ],
    "Social": [
      "Message a friend you haven't talked to in a while",
      "Join a community event",
      "Introduce yourself to someone new",
      "Have a meaningful conversation",
      "Do a random act of kindness"
    ],
  };

  Map<String, List<String>> generatedTasks = {};
  Map<String, Map<String, bool>> taskCompletionStatus = {};
  Map<String, DateTime?> taskTimers = {};
  Map<String, bool> tasksCompleted = {};
  Map<String, String> lastUpdatedDates = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final sessionBox = await Hive.openBox('session');
    final userId = sessionBox.get('loggedInUser');
    if (userId == null) return;

    setState(() {
      _userId = userId;
    });

    final box = await Hive.openBox('selfCareTasks');
    final data = box.get(userId);
    if (data != null) {
      final decoded = jsonDecode(data);
      setState(() {
        generatedTasks = Map<String, List<String>>.from(
          (decoded['generatedTasks'] ?? {}).map((key, val) => MapEntry(key, List<String>.from(val)))
        );
        taskCompletionStatus = Map<String, Map<String, bool>>.from(
          (decoded['taskCompletionStatus'] ?? {}).map((key, val) => MapEntry(key, Map<String, bool>.from(val)))
        );
        taskTimers = Map<String, DateTime?>.from(
          (decoded['taskTimers'] ?? {}).map((key, val) => MapEntry(key, val != null ? DateTime.parse(val) : null))
        );
        tasksCompleted = Map<String, bool>.from(decoded['tasksCompleted'] ?? {});
        lastUpdatedDates = Map<String, String>.from(decoded['lastUpdatedDates'] ?? {});
      });
    }

    _checkCompletionStatus();
  }

  Future<void> _saveUserData() async {
    if (_userId == null) return;
    final box = await Hive.openBox('selfCareTasks');
    final data = jsonEncode({
      'generatedTasks': generatedTasks,
      'taskCompletionStatus': taskCompletionStatus,
      'taskTimers': taskTimers.map((key, value) => MapEntry(key, value?.toIso8601String())),
      'tasksCompleted': tasksCompleted,
      'lastUpdatedDates': lastUpdatedDates,
    });
    await box.put(_userId, data);
  }

  void _checkCompletionStatus() {
    final today = DateTime.now().toIso8601String().split("T").first;

    if (lastUpdatedDates[selectedType] != today) {
      generatedTasks[selectedType] = List<String>.from(selfCareTasks[selectedType]!);
      generatedTasks[selectedType]!.shuffle();
      generatedTasks[selectedType] = generatedTasks[selectedType]!.take(3).toList();
      taskCompletionStatus[selectedType] = {
        for (var task in generatedTasks[selectedType]!) task: false,
      };
      taskTimers[selectedType] = DateTime.now().add(const Duration(hours: 24));
      lastUpdatedDates[selectedType] = today;
    }

    bool allCompleted = taskCompletionStatus[selectedType]!.values.every((c) => c);
    bool expired = DateTime.now().isAfter(taskTimers[selectedType]!);

    tasksCompleted[selectedType] = allCompleted || expired;
    _saveUserData();
  }

  Widget _buildToggleButton(String text) {
    bool isSelected = selectedType == text;
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF40D404)
                : Colors.lightGreen)
            : (Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.grey[400]),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 3,
        ),
        onPressed: () {
          setState(() {
            selectedType = text;
            _checkCompletionStatus();
          });
        },
        child: Text(
          text,
          style: TextStyle(
            fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
            fontWeight: FontWeight.bold,
            color: isSelected
              ? Colors.black
              : Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTaskList() {
    return generatedTasks[selectedType]?.map((task) => Theme(
      data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.black),
      child: CheckboxListTile(
        value: taskCompletionStatus[selectedType]?[task] ?? false,
        onChanged: (value) {
          setState(() {
            taskCompletionStatus[selectedType]![task] = value ?? false;
          });
          _saveUserData();
          _checkCompletionStatus();
        },
        title: Text(
          task,
          style: TextStyle(
            fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: Colors.transparent,
        checkColor: Colors.black,
      ),
    )).toList() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    double containerWidth = MediaQuery.of(context).size.width * 0.9;
    _checkCompletionStatus();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: containerWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.blue.shade300
                  : Colors.blue.shade300,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    "Select self-care type",
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildToggleButton("Physical"),
                      const SizedBox(width: 10),
                      _buildToggleButton("Emotional"),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildToggleButton("Mental"),
                      const SizedBox(width: 10),
                      _buildToggleButton("Social"),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: containerWidth,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade300,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Column(
                children: tasksCompleted[selectedType] == true
                    ? [
                        Text(
                          "Tasks complete! 🎉",
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        )
                      ]
                    : _buildTaskList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
