import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mindshed_app/badges_screen.dart';
import 'package:mindshed_app/goals_screen.dart';
import 'package:mindshed_app/home_screen.dart';
import 'package:mindshed_app/insights_engine.dart';
import 'package:mindshed_app/insights_screen.dart';
import 'package:mindshed_app/settings_screen.dart';
import 'package:mindshed_app/activities_screen.dart';
import 'package:mindshed_app/transition_helper.dart';
import 'package:mindshed_app/edit_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 4;
  String _username = '';
  String? _petName;
  String _petMood = 'Unknown';
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await Hive.openBox('session');
    await Hive.openBox('dailyMetrics');
    await Hive.openBox('petNames');
    await _updateLoginStreak();
    await _loadUserInfo();
  }

  Future<void> _updateLoginStreak() async {
    final sessionBox = Hive.box('session');
    final userId = sessionBox.get('loggedInUser') as String?;
    if (userId == null) return;

    final streakKey = '${userId}_currentStreak';
    final loginKey  = '${userId}_lastLoginDate';
    final xpKey     = '${userId}_totalXp';

    final lastLoginMillis = sessionBox.get(loginKey) as int?;
    final storedStreak    = sessionBox.get(streakKey) as int? ?? 0;
    final now             = DateTime.now();
    final today           = DateTime(now.year, now.month, now.day);

    // Fix: Initialize lastDate properly and use proper comparison
    DateTime? lastDate;
    if (lastLoginMillis != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(lastLoginMillis);
      lastDate = DateTime(dt.year, dt.month, dt.day);
    }

    // Logic to determine the new streak value
    int newStreak;
    
    if (lastDate == null) {
      // First login ever
      newStreak = 1;
    } else if (lastDate.isAtSameMomentAs(today)) {
      // Already logged in today, keep current streak
      newStreak = storedStreak;
    } else if (today.difference(lastDate).inDays == 1) {
      // Logged in yesterday, increment streak
      newStreak = storedStreak + 1;
    } else if (today.difference(lastDate).inDays > 1) {
      // Missed at least one day, reset streak
      newStreak = 1;
    } else {
      // This case should not happen (future date), but keep current streak
      newStreak = storedStreak;
    }

    // Reward XP for milestone streaks
    final xpGain = <int,int>{3:5, 7:10, 14:20, 30:50, 60:100, 90:150, 180:300, 365:1000};
    if (xpGain.containsKey(newStreak) && newStreak != storedStreak) {
      final currentXp = sessionBox.get(xpKey) as int? ?? 0;
      await sessionBox.put(xpKey, currentXp + xpGain[newStreak]!);
    }

    // Always update the last login date to today and save the new streak
    await sessionBox.put(loginKey, today.millisecondsSinceEpoch);
    await sessionBox.put(streakKey, newStreak);

    if (mounted) {
      setState(() {
        _streak = newStreak;
      });
    }
  }

  Future<void> _loadUserInfo() async {
    final sessionBox = Hive.box('session');
    final metricsBox = Hive.box('dailyMetrics');
    final petBox     = Hive.box('petNames');
    final userId     = sessionBox.get('loggedInUser') as String?;
    if (userId != null) {
      final storedPetName = petBox.get(userId) as String?;
      final engine = InsightsEngine(metricsBox);
      final score = await engine.getPredictedScore(userId, DateRange.daily);
      String mood = 'Normal';
      if (score >= 80) mood = 'Excited';
      else if (score >= 60) mood = 'Happy';
      else if (score >= 40) mood = 'Okay';
      else if (score >= 20) mood = 'Tired';
      else if (score > 0) mood = 'Sad';

      if (mounted) {
        setState(() {
          _username = userId;
          _petName  = storedPetName;
          _petMood  = score == 0 ? 'Normal' : mood;
        });
      }
    }
  }

  Future<void> _renamePet() async {
    final controller = TextEditingController(text: _petName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Your Pet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter pet name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != _petName) {
      final sessionBox = Hive.box('session');
      final petBox     = Hive.box('petNames');
      final userId     = sessionBox.get('loggedInUser') as String?;
      if (userId != null) {
        await petBox.put(userId, newName);

        final xpKey    = '${userId}_totalXp';
        final currentXp = sessionBox.get(xpKey) as int? ?? 0;
        await sessionBox.put(xpKey, currentXp + 10);

        setState(() {
          _petName = newName;
        });
      }
    }
  }

  Widget _buildLabelButton(
    String label, {
    Color? bgColor,
    Color? textColor,
    double? fontSize,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor ?? (isDark ? const Color(0xFF2C2F36) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: fontSize,
            color: textColor ?? (isDark ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final fontSize  = Theme.of(context).textTheme.bodyMedium?.fontSize;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person, size: 60, color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLabelButton('$_username', fontSize: fontSize),
                          _buildLabelButton('Current Streak: $_streak', fontSize: fontSize),
                          _buildLabelButton(
                            'Edit Details',
                            bgColor: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF40D404)
                                : const Color(0xFFB6FFB1),
                            fontSize: fontSize,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (c) => const EditDetailsScreen()))
                                  .then((_) => _loadUserInfo());
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildLabelButton(
                        'View Badges',
                        bgColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF40D404)
                            : const Color(0xFFB6FFB1),
                        fontSize: fontSize,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BadgesScreen())),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildLabelButton(
                        'Goals',
                        bgColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF40D404)
                            : const Color(0xFFB6FFB1),
                        fontSize: fontSize,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset('assets/images/pet.jpg', width: 100, height: 100, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLabelButton(
                            _petName == null || _petName!.isEmpty ? 'Set your pet name' : '$_petName',
                            fontSize: fontSize,
                            onTap: _renamePet,
                          ),
                          _buildLabelButton('Customize Pet', fontSize: fontSize, textColor: Colors.grey),
                          _buildLabelButton('Current Mood: $_petMood', fontSize: fontSize),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'You are exactly where you need to be.\n\nTrust the path and keep moving forward.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: fontSize,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildCustomBottomBar(),
    );
  }

  Widget _buildCustomBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(icon: Icons.settings, index: 0),
          _buildNavItem(icon: Icons.auto_graph, index: 1),
          _buildNavItem(icon: Icons.home, index: 2),
          _buildNavItem(icon: Icons.self_improvement, index: 3),
          _buildNavItem(icon: Icons.person, index: 4, isHome: true),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index, bool isHome = false}) {
    final isSelected = (_selectedIndex == index);
    final fillColor = isSelected
        ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF40D404) : const Color(0xFFB6FFB1))
        : Theme.of(context).colorScheme.surface;
    final iconColor = isSelected ? Colors.black : Colors.grey[700];

    return Material(
      elevation: 3,
      shape: const CircleBorder(side: BorderSide(color: Colors.black)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          setState(() => _selectedIndex = index);
          if (index == 0) Navigator.pushReplacement(context, createFadeRoute(const SettingsScreen()));
          if (index == 1) Navigator.pushReplacement(context, createFadeRoute(const InsightsScreen()));
          if (index == 2) Navigator.pushReplacement(context, createFadeRoute(const HomeScreen()));
          if (index == 3) Navigator.pushReplacement(context, createFadeRoute(const ActivitiesScreen()));
          if (index == 4) Navigator.pushReplacement(context, createFadeRoute(const ProfileScreen()));
        },
        child: Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, color: fillColor), child: Icon(icon, color: iconColor)),
      ),
    );
  }
}