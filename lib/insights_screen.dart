import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mindshed_app/home_screen.dart';
import 'package:mindshed_app/settings_screen.dart';
import 'package:mindshed_app/activities_screen.dart';
import 'package:mindshed_app/profile_screen.dart';
import 'package:mindshed_app/transition_helper.dart';
import 'package:mindshed_app/insights_engine.dart' show DateRange, Grade, InsightsEngine;

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;
  DateRange _selectedRange = DateRange.daily;

  int _overallScore = 0;
  Color _gradeColour = Colors.grey;

  Map<String, Grade> _categoryGrades = {};

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  late Box _metricsBox;

  bool _isLoading = false;
  String? _error;
  InsightsEngine? _engine;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Initialize asynchronously
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      _metricsBox = await Hive.openBox('dailyMetrics');
      if (mounted) {
        _loadInsights();
      }
    } catch (e) {
      print('Error initializing metrics box: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize data';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String _capitalizeWords(String input) => input
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  Future<void> _loadInsights() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final sessionBox = await Hive.openBox('session');
      final userId = sessionBox.get('loggedInUser');

      if (userId == null || userId.toString().isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'User not logged in';
          });
        }
        return;
      }

      if (_engine == null) {
        _engine = InsightsEngine(_metricsBox);
        await _engine!.initPredictor();
      }

      final score = await _engine!.getPredictedScore(userId, _selectedRange);
      final grades = await _engine!.getCategoryGrades(userId, _selectedRange);

      if (mounted) {
        setState(() {
          _overallScore = score;
          _categoryGrades = grades;
          _isLoading = false;
          _error = null;

          _gradeColour = _overallScore >= 75
              ? Colors.green
              : _overallScore >= 50
                  ? Colors.amber
                  : Colors.red;
        });

        _fadeController.forward(from: 0);
      }
    } catch (e) {
      print('Error loading insights: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load insights';
        });
      }
    }
  }

  void _onDateRangeChanged(DateRange range) {
    setState(() => _selectedRange = range);
    _loadInsights();
  }


  String _pretty(String k) {
    switch (k) {
      case 'sleep_bucket':            return 'Sleep';
      case 'exercise_bucket':         return 'Exercise';
      case 'hydration_bucket':        return 'Hydration';
      case 'mindfulness_activities':  return 'Mindfulness';
      default: 
        return _capitalizeWords(k.replaceAll('_', ' '));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color;
    final fontSize = theme.textTheme.bodyMedium?.fontSize;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
        title: Text('Insights',
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: fontSize,
              color: textColor,
            )),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
          : SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildTopRow(fontSize, textColor),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _categoryGrades.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            'No insights available.\nStart logging your wellness data to see insights.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'HappyMonkey',
                              fontSize: fontSize ?? 16,
                              color: textColor,
                            ),
                          ),
                        )
                      : Column(
                          children: _categoryGrades.entries
                              .map((e) => _buildGradeCard(
                                  e.key, e.value, fontSize, textColor))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 30),
              ],
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
          _buildNavItem(icon: Icons.auto_graph, index: 1, isHome: true),
          _buildNavItem(icon: Icons.home, index: 2),
          _buildNavItem(icon: Icons.self_improvement, index: 3),
          _buildNavItem(icon: Icons.person, index: 4)
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

  Widget _buildTopRow(double? fontSize, Color? textColor) => Row(
        children: [
          Expanded(child: _buildDateRangeCard(fontSize, textColor)),
          const SizedBox(width: 10),
          Expanded(child: _buildWellnessScoreCard(fontSize, textColor)),
        ],
      );

  Widget _buildDateRangeCard(double? fontSize, Color? textColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text('Select Date Range',
                style: TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: fontSize,
                    color: textColor)),
            const SizedBox(height: 10),
            _dateRangeOption(DateRange.daily, 'Daily', fontSize),
            const Divider(),
            _dateRangeOption(DateRange.weekly, 'Weekly', fontSize),
            const Divider(),
            _dateRangeOption(DateRange.monthly, 'Monthly', fontSize),
          ],
        ),
      );

  Widget _dateRangeOption(DateRange range, String label, double? fontSize) {
    final selected = _selectedRange == range;
    return GestureDetector(
      onTap: () => _onDateRangeChanged(range),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'HappyMonkey',
          fontSize: fontSize,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : (selected ? Colors.black : Colors.black45),
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildWellnessScoreCard(double? fontSize, Color? textColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text('Overall\nWellness Score',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: fontSize,
                    color: textColor)),
            const SizedBox(height: 8),
            SizedBox(
              width: 60,
              height: 86,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: _overallScore / 100),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, _) => Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey[300],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_gradeColour),
                      ),
                    ),
                    Text('$_overallScore%',
                        style: TextStyle(
                            fontFamily: 'HappyMonkey',
                            fontSize: fontSize,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                        ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildGradeCard(
      String key, 
      Grade grade, 
      double? fontSize, 
      Color? textColor) {
    // Default values if nulls are provided
    final finalFontSize = fontSize ?? 14.0;
    final finalTextColor = textColor ?? Colors.black;
    
    // Define styling based on grade
    Color cardColor;
    String description;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (grade) {
      case Grade.green:
        cardColor = isDark ? const Color(0xFF2ECC71) : const Color(0xFFB6FFB1);
        description = 'Excellent';
        break;
      case Grade.amber:
        cardColor = isDark ? const Color(0xFFF4D03F) : const Color(0xFFFFDC75);
        description = 'Moderate';
        break;
      case Grade.red:
        cardColor = isDark ? const Color(0xFFE74C3C) : const Color(0xFFFF8A7D);
        description = 'Needs Attention';
        break;
    }
    
    return Container(
      key: ValueKey('grade_card_$key'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black),
        color: cardColor.withOpacity(0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _pretty(key),
              style: TextStyle(
                fontFamily: 'HappyMonkey',
                fontSize: finalFontSize,
                color: finalTextColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            description,
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: finalFontSize,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
    }