import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> with TickerProviderStateMixin {
  final TextEditingController _goalNameController = TextEditingController();
  final TextEditingController _goalDescriptionController = TextEditingController();

  List<Map<String, String>> goals = [];
  Set<int> expandedIndexes = {};
  Set<int> fadingIndexes = {};
  late Box _sessionBox;
  late Box _goalBox;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    _sessionBox = await Hive.openBox('session');
    _goalBox = await Hive.openBox('userGoals');

    _userId = _sessionBox.get('loggedInUser');
    if (_userId == null) return;

    _loadGoals();
  }

  void _addGoal() async {
    final name = _goalNameController.text.trim();
    final description = _goalDescriptionController.text.trim();

    if (name.isNotEmpty && description.isNotEmpty) {
      setState(() {
        goals.insert(0, {
          'title': name,
          'description': description,
        });
      });

      _goalNameController.clear();
      _goalDescriptionController.clear();
      await _saveGoals();
    }
  }

  Future<void> _saveGoals() async {
    if (_userId == null) return;
    await _goalBox.put(_userId, goals);
  }

  void _loadGoals() {
    final stored = _goalBox.get(_userId);
    if (stored != null && stored is List) {
      setState(() {
        goals = List<Map<String, String>>.from(
          stored.map((e) => Map<String, String>.from(e)),
        );
      });
    }
  }

  void _fadeAndRemoveGoal(int index) {
    setState(() {
      fadingIndexes.add(index);
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          goals.removeAt(index);
          expandedIndexes.remove(index);
          fadingIndexes.remove(index);
        });
        _saveGoals();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyMedium?.fontSize;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Goals',
          style: TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: fontSize,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildGoalForm(fontSize),
            const SizedBox(height: 16),
            _buildGoalList(fontSize),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalForm(double? fontSize) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardBox(),
      child: Column(
        children: [
          Text(
            'Make a personal goal',
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _goalNameController,
            decoration: _inputDecoration('Goal Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _goalDescriptionController,
            maxLines: 4,
            decoration: _inputDecoration('Describe your goal!'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _addGoal,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF40D404)
                  : const Color(0xFFB6FFB1),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Add Goal',
              style: TextStyle(
                fontFamily: 'HappyMonkey',
                fontSize: fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalList(double? fontSize) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: _cardBox(),
      child: goals.isEmpty
          ? Text(
        "It looks like you don’t have any goals.\nWhy not make one?",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'HappyMonkey',
          fontSize: fontSize,
        ),
      )
          : Column(
        children: goals.asMap().entries.map((entry) {
          final index = entry.key;
          final goal = entry.value;
          final isExpanded = expandedIndexes.contains(index);
          final isFading = fadingIndexes.contains(index);

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isFading ? 0.0 : 1.0,
            child: IgnorePointer(
              ignoring: isFading,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF40D404)
                      : const Color(0xFFDFFFD5),
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: false,
                      onChanged: (_) => _fadeAndRemoveGoal(index),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              expandedIndexes.remove(index);
                            } else {
                              expandedIndexes.add(index);
                            }
                          });
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal['title'] ?? '',
                              style: TextStyle(
                                fontFamily: 'HappyMonkey',
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isExpanded) ...[
                              const SizedBox(height: 8),
                              Text(
                                goal['description'] ?? '',
                                style: TextStyle(
                                  fontFamily: 'HappyMonkey',
                                  fontSize: fontSize,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  BoxDecoration _cardBox() {
    return BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2C2F36)
          : const Color(0xFFD4E7C5),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.black, width: 1.5),
    );
  }
}