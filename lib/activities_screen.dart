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

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final fontSize = Theme.of(context).textTheme.bodyMedium?.fontSize;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          showJournalScreen
              ? 'My Journal'
              : showGuidedBreathingScreen
                  ? 'Meditation'
                  : showSelfCareScreen
                      ? 'Self Care'
                      : showQuizScreen
                          ? 'Quizzes'
                          : 'Activities',
          style: TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: (fontSize ?? 18) + 6,
            color: textColor,
          ),
        ),
        leading: (showJournalScreen ||
                showGuidedBreathingScreen ||
                showSelfCareScreen ||
                showQuizScreen)
            ? IconButton(
                icon: Icon(Icons.arrow_back,
                    color: Theme.of(context).iconTheme.color),
                onPressed: () {
                  setState(() {
                    showJournalScreen = false;
                    showGuidedBreathingScreen = false;
                    showSelfCareScreen = false;
                    showQuizScreen = false;
                  });
                },
              )
            : null,
      ),
      body: showJournalScreen
          ? const JournalScreen()
          : showGuidedBreathingScreen
              ? const GuidedBreathingScreen()
              : showSelfCareScreen
                  ? const SelfCareScreen()
                  : showQuizScreen
                      ? const QuizScreen()
                      : _buildActivityGrid(fontSize),
      bottomNavigationBar: _buildCustomBottomBar(),
    );
  }

  Widget _buildActivityGrid(double? fontSize) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildActivityButton(
                  Icons.menu_book,
                  "My Journal",
                  fontSize,
                  () {
                    setState(() {
                      showJournalScreen = true;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildActivityButton(
                  Icons.psychology,
                  "Guided Breathing",
                  fontSize,
                  () {
                    setState(() {
                      showGuidedBreathingScreen = true;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildActivityButton(
                  Icons.people,
                  "Self Care",
                  fontSize,
                  () {
                    setState(() {
                      showSelfCareScreen = true;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildActivityButton(
                  Icons.quiz,
                  "Quizzes",
                  fontSize,
                  () {
                    setState(() {
                      showQuizScreen = true;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildActivityButton(
                  Icons.show_chart,
                  "Input Data",
                  fontSize,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const InputMetricsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityButton(
      IconData icon, String label, double? fontSize, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Material(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF40D404) : const Color(0xFFB6FFB1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: Colors.black, size: 28),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: fontSize ?? 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(icon: Icons.settings, index: 0),
          _buildNavItem(icon: Icons.auto_graph, index: 1),
          _buildNavItem(icon: Icons.home, index: 2),
          _buildNavItem(icon: Icons.self_improvement, index: 3, isHome: true),
          _buildNavItem(icon: Icons.person, index: 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      {required IconData icon, required int index, bool isHome = false}) {
    final bool isSelected = (_selectedIndex == index);
    Color fillColor = isSelected
        ? (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF40D404)
            : const Color(0xFFB6FFB1))
        : Theme.of(context).colorScheme.surface;
    final iconColor = isSelected ? Colors.black : Colors.grey[700];

    return Material(
      elevation: 3,
      shape: const CircleBorder(side: BorderSide(color: Colors.black)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            Navigator.pushReplacement(
                context, createFadeRoute(const SettingsScreen()));
          } else if (index == 1) {
            Navigator.pushReplacement(
                context, createFadeRoute(const InsightsScreen()));
          } else if (index == 2) {
            Navigator.pushReplacement(
                context, createFadeRoute(const HomeScreen()));
          } else if (index == 3) {
            Navigator.pushReplacement(
                context, createFadeRoute(const ActivitiesScreen()));
          } else if (index == 4) {
            Navigator.pushReplacement(
                context, createFadeRoute(const ProfileScreen()));
          }
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(shape: BoxShape.circle, color: fillColor),
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }
}
