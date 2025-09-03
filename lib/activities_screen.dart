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
import 'shared_navigation.dart';
import 'shared_ui_components.dart';

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
  static const Color _cream = SharedUIComponents.cream;
  static const Color _mint = SharedUIComponents.mint;

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
      bottomNavigationBar: SharedNavigation.buildBottomNavigation(
        selectedIndex: _selectedIndex,
        context: context,
      ),
    );
  }

  // ===== UI pieces =====

  Widget _pillHeader() {
    final fontSize =
        (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 18) + 4;
    return SharedUIComponents.buildHeaderPill('Activities', fontSize: fontSize);
  }

  Widget _activityCard(BuildContext context) {
    return SharedUIComponents.buildCard(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          SharedUIComponents.buildActivityButton(
            icon: Icons.menu_book_outlined,
            label: 'My Journal',
            onTap: () => setState(() => showJournalScreen = true),
            backgroundColor: const Color(0xFFE8F5E8), // Light green
          ),
          const SizedBox(height: 16),
          SharedUIComponents.buildActivityButton(
            icon: Icons.psychology_outlined,
            label: 'Guided Breathing',
            onTap: () => setState(() => showGuidedBreathingScreen = true),
            backgroundColor: const Color(0xFFE3F2FD), // Light blue
          ),
          const SizedBox(height: 16),
          SharedUIComponents.buildActivityButton(
            icon: Icons.people_outline,
            label: 'Self Care',
            onTap: () => setState(() => showSelfCareScreen = true),
            backgroundColor: const Color(0xFFF3E5F5), // Light purple
          ),
          const SizedBox(height: 16),
          SharedUIComponents.buildActivityButton(
            icon: Icons.description_outlined,
            label: 'Quizzes',
            onTap: () => setState(() => showQuizScreen = true),
            backgroundColor: const Color(0xFFFFF3E0), // Light orange
          ),
          const SizedBox(height: 16),
          SharedUIComponents.buildActivityButton(
            icon: Icons.show_chart_outlined,
            label: 'Input Data',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InputMetricsScreen()),
              );
            },
            backgroundColor: const Color(0xFFE0F2F1), // Light teal
          ),
        ],
      ),
    );
  }
}
