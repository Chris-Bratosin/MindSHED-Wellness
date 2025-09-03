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
import 'shared_navigation.dart';
import 'shared_ui_components.dart';

import 'pet_panel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // palette
  static const cream = SharedUIComponents.cream;
  static const mint = SharedUIComponents.mint;

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
    final loginKey = '${userId}_lastLoginDate';
    final xpKey = '${userId}_totalXp';

    final lastLoginMillis = sessionBox.get(loginKey) as int?;
    final storedStreak = sessionBox.get(streakKey) as int? ?? 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? lastDate;
    if (lastLoginMillis != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(lastLoginMillis);
      lastDate = DateTime(dt.year, dt.month, dt.day);
    }

    int newStreak;
    if (lastDate == null) {
      newStreak = 1;
    } else if (lastDate.isAtSameMomentAs(today)) {
      newStreak = storedStreak;
    } else if (today.difference(lastDate).inDays == 1) {
      newStreak = storedStreak + 1;
    } else if (today.difference(lastDate).inDays > 1) {
      newStreak = 1;
    } else {
      newStreak = storedStreak;
    }

    const xpGain = <int, int>{
      3: 5,
      7: 10,
      14: 20,
      30: 50,
      60: 100,
      90: 150,
      180: 300,
      365: 1000,
    };
    if (xpGain.containsKey(newStreak) && newStreak != storedStreak) {
      final currentXp = sessionBox.get(xpKey) as int? ?? 0;
      await sessionBox.put(xpKey, currentXp + xpGain[newStreak]!);
    }

    await sessionBox.put(loginKey, today.millisecondsSinceEpoch);
    await sessionBox.put(streakKey, newStreak);
    if (mounted) setState(() => _streak = newStreak);
  }

  Future<void> _loadUserInfo() async {
    final sessionBox = Hive.box('session');
    final metricsBox = Hive.box('dailyMetrics');
    final petBox = Hive.box('petNames');

    final userId = sessionBox.get('loggedInUser') as String?;
    if (userId == null) return;

    final storedPetName = petBox.get(userId) as String?;
    final engine = InsightsEngine(metricsBox);
    final score = await engine.getPredictedScore(userId, DateRange.daily);

    String mood = 'Normal';
    if (score >= 80)
      mood = 'Excited';
    else if (score >= 60)
      mood = 'Happy';
    else if (score >= 40)
      mood = 'Okay';
    else if (score >= 20)
      mood = 'Tired';
    else if (score > 0)
      mood = 'Sad';

    if (mounted) {
      setState(() {
        _username = userId;
        _petName = storedPetName;
        _petMood = score == 0 ? 'Normal' : mood;
      });
    }
  }

  // ---- small UI helpers ----
  Widget _pillHeader(String title) => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
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

  @override
  Widget build(BuildContext context) {
    final fs = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16.0;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          children: [
            SharedUIComponents.buildHeaderPill('My Profile', fontSize: fs + 4),
            const SizedBox(height: 12),

            // top card
            SharedUIComponents.buildCard(
              child: Row(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 56,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SharedUIComponents.buildLabelChip(_username),
                        const SizedBox(height: 8),
                        SharedUIComponents.buildLabelChip(
                          'Current Streak: $_streak',
                        ),
                        const SizedBox(height: 8),
                        SharedUIComponents.buildMintButton(
                          label: 'Edit Details',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditDetailsScreen(),
                              ),
                            ).then((_) => _loadUserInfo());
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            SharedUIComponents.buildCard(child: PetPanel()),

            const SizedBox(height: 12),
            // quote
            SharedUIComponents.buildCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Text(
                      'You are exactly where you need to be.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'HappyMonkey',
                        fontSize: fs,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Trust the path and keep moving forward.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'HappyMonkey', fontSize: fs),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // badges & goals
            SharedUIComponents.buildCard(
              child: Row(
                children: [
                  Expanded(
                    child: SharedUIComponents.buildMintButton(
                      label: 'Badges',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BadgesScreen(),
                          ),
                        );
                      },
                      icon: Icons.emoji_events,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SharedUIComponents.buildMintButton(
                      label: 'Goals',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GoalsScreen(),
                          ),
                        );
                      },
                      icon: Icons.track_changes,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // NEW NAV BAR (rounded squares, selected = mint)
      bottomNavigationBar: SharedNavigation.buildBottomNavigation(
        selectedIndex: _selectedIndex,
        context: context,
      ),
    );
  }
}
