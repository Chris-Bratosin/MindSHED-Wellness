import 'package:flutter/material.dart';
import 'package:mindshed_app/input_metrics_screen.dart';

import 'home_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'insights_screen.dart';
import 'journal_screen.dart';
import 'guided_breathing_screen.dart';
import 'self_care_screen.dart';
import 'quiz_screen.dart';
import 'transition_helper.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  bool showJournalScreen = false;
  bool showGuidedBreathingScreen = false;
  bool showSelfCareScreen = false;
  bool showQuizScreen = false;
  int _selectedIndex = 3;

  // ——— styles
  static const Color _cream = Color(0xFFFFF9DA);
  static const Color _mint = Color(0xFFB6FFB1);

  @override
  Widget build(BuildContext context) {
    // If a sub-screen is active, just show it (your existing flow).
    if (showJournalScreen) return const JournalScreen();
    if (showGuidedBreathingScreen) return const GuidedBreathingScreen();
    if (showSelfCareScreen) return const SelfCareScreen();
    if (showQuizScreen) return const QuizScreen();

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _pillHeader(),
            const SizedBox(height: 18),
            _activityCard(context),
            const SizedBox(height: 28),
            // Mascot spacer — you’ll add your widget here.
            const SizedBox(height: 160),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ===== UI pieces =====

  Widget _pillHeader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Text(
          'Activities',
          style: TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: 24,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _activityCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          _activityButton(
            icon: Icons.menu_book_outlined,
            label: 'My Journal',
            onTap: () => setState(() => showJournalScreen = true),
          ),
          const SizedBox(height: 16),
          _activityButton(
            icon: Icons.psychology_outlined,
            label: 'Guided\nBreathing',
            onTap: () => setState(() => showGuidedBreathingScreen = true),
            twoLine: true,
          ),
          const SizedBox(height: 16),
          _activityButton(
            icon: Icons.people_outline,
            label: 'Self Care',
            onTap: () => setState(() => showSelfCareScreen = true),
          ),
          const SizedBox(height: 16),
          _activityButton(
            icon: Icons.description_outlined,
            label: 'Quizzes',
            onTap: () => setState(() => showQuizScreen = true),
          ),
          const SizedBox(height: 16),
          _activityButton(
            icon: Icons.show_chart_outlined,
            label: 'Input Data',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InputMetricsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _activityButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool twoLine = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: _mint,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [
            // subtle drop shadow like the mock
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Left icon in a soft rounded square to mimic the extra padding
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: _mint,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black, width: 2),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 28, color: Colors.black),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                maxLines: twoLine ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'HappyMonkey',
                  fontSize: 20,
                  height: 1.05,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              color: Colors.black26,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navItem(Icons.settings, 0),
            _navItem(Icons.auto_graph, 1),
            _navItem(Icons.home, 2),
            _navItem(Icons.self_improvement, 3),
            _navItem(Icons.person, 4),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int idx) {
    final bool isSelected = (_selectedIndex == idx);
    final Color mint = const Color(0xFFB6FFB1);

    return Material(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black, width: 2),
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
            color: isSelected ? mint : Colors.white,     // white idle, mint selected
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(                                  // soft drop like the mock
                color: Colors.black26,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 24,
            color: isSelected ? Colors.black : Colors.grey[800],
          ),
        ),
      ),
    );
  }

}
