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

import 'pet_panel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // palette
  static const cream = Color(0xFFFFF9DA);
  static const mint  = Color(0xFFB6FFB1);

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
    final now   = DateTime.now();
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

    const xpGain = <int, int>{3:5, 7:10, 14:20, 30:50, 60:100, 90:150, 180:300, 365:1000};
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
    final petBox     = Hive.box('petNames');

    final userId = sessionBox.get('loggedInUser') as String?;
    if (userId == null) return;

    final storedPetName = petBox.get(userId) as String?;
    final engine = InsightsEngine(metricsBox);
    final score  = await engine.getPredictedScore(userId, DateRange.daily);

    String mood = 'Normal';
    if (score >= 80)      mood = 'Excited';
    else if (score >= 60) mood = 'Happy';
    else if (score >= 40) mood = 'Okay';
    else if (score >= 20) mood = 'Tired';
    else if (score > 0)   mood = 'Sad';

    if (mounted) {
      setState(() {
        _username = userId;
        _petName  = storedPetName;
        _petMood  = score == 0 ? 'Normal' : mood;
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
          )
        ],
      ),
      child: Text(title,
          style: const TextStyle(
              fontFamily: 'HappyMonkey', fontSize: 22, color: Colors.black)),
    ),
  );

  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.black, width: 2),
      boxShadow: [
        BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3))
      ],
    ),
    child: child,
  );

  Widget _labelChip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F1F1),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.black, width: 1.6),
    ),
    child: Text(text,
        textAlign: TextAlign.center,
        style:
        const TextStyle(fontFamily: 'HappyMonkey', color: Colors.black)),
  );

  Widget _mintBtn(String label, VoidCallback onTap, {IconData? icon}) => Material(
    color: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: Colors.black, width: 2),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    color: Colors.black,
                    fontWeight: FontWeight.w600)),
          ],
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
            _pillHeader('My Profile'),
            const SizedBox(height: 12),

            // top card
            _card(Row(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(Icons.person, size: 56, color: Colors.black),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _labelChip(_username),
                      const SizedBox(height: 8),
                      _labelChip('Current Streak: $_streak'),
                      const SizedBox(height: 8),
                      _mintBtn('Edit Details', () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const EditDetailsScreen()))
                            .then((_) => _loadUserInfo());
                      }),
                    ],
                  ),
                ),
              ],
            )),

            const SizedBox(height: 12),
            _card(PetPanel(
            )),

            const SizedBox(height: 12),
            // quote
            _card(Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Column(
                children: [
                  Text('You are exactly where you need to be.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'HappyMonkey',
                          fontSize: fs,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text('Trust the path and keep moving forward.',
                      textAlign: TextAlign.center,
                      style:
                      TextStyle(fontFamily: 'HappyMonkey', fontSize: fs)),
                ],
              ),
            )),

            const SizedBox(height: 12),

            // badges & goals
            _card(Row(
              children: [
                Expanded(
                  child: _mintBtn('Badges', () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const BadgesScreen()));
                  }, icon: Icons.emoji_events),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _mintBtn('Goals', () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const GoalsScreen()));
                  }, icon: Icons.track_changes),
                ),
              ],
            )),
          ],
        ),
      ),

      // NEW NAV BAR (rounded squares, selected = mint)
      bottomNavigationBar: _navBarV2(),
    );
  }

  Widget _navBarV2() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 30),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navSquare(icon: Icons.settings, index: 0),
          _navSquare(icon: Icons.auto_graph, index: 1),
          _navSquare(icon: Icons.home, index: 2),
          _navSquare(icon: Icons.self_improvement, index: 3),
          _navSquare(icon: Icons.person, index: 4),
        ],
      ),
    );
  }

  Widget _navSquare({required IconData icon, required int index}) {
    final selected = _selectedIndex == index;
    final bg = selected ? mint : Colors.white;
    final ic = selected ? Colors.black : Colors.black87;

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() => _selectedIndex = index);
          if (index == 0) {
            Navigator.pushReplacement(context, createFadeRoute(const SettingsScreen()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, createFadeRoute(const InsightsScreen()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, createFadeRoute(const HomeScreen()));
          } else if (index == 3) {
            Navigator.pushReplacement(context, createFadeRoute(const ActivitiesScreen()));
          } else if (index == 4) {
            Navigator.pushReplacement(context, createFadeRoute(const ProfileScreen()));
          }
        },
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
          ),
          child: Icon(icon, color: ic, size: 26),
        ),
      ),
    );
  }
}
