import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mindshed_app/home_screen.dart';
import 'package:mindshed_app/settings_screen.dart';
import 'package:mindshed_app/activities_screen.dart';
import 'package:mindshed_app/profile_screen.dart';
import 'package:mindshed_app/transition_helper.dart';
import 'package:mindshed_app/insights_engine.dart'
    show DateRange, Grade, InsightsEngine;

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 1;
  DateRange _selectedRange = DateRange.daily;

  int _overallScore = 0;
  Color _gradeColour = Colors.grey;

  Map<String, Grade> _categoryGrades = {};

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final PageController _dateRangeController;

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

    _dateRangeController =
        PageController(initialPage: 0); // Start with daily (top)

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
    _dateRangeController.dispose();
    super.dispose();
  }

  String _capitalizeWords(String input) => input
      .split(' ')
      .map((w) => w.isEmpty
          ? w
          : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
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
      case 'sleep_bucket':
        return 'Sleep';
      case 'exercise_bucket':
        return 'Exercise';
      case 'hydration_bucket':
        return 'Hydration';
      case 'mindfulness_activities':
        return 'Mindfulness';
      default:
        return _capitalizeWords(k.replaceAll('_', ' '));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color;
    final fontSize = theme.textTheme.bodyMedium?.fontSize;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF1C1D22),
                  const Color(0xFF2A2B30),
                ]
              : [
                  const Color(0xFFE8E8E8),
                  Colors.white,
                ],
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Wellness Insights',
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: (fontSize ?? 16) + 2,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState(_error!, textColor)
                : SafeArea(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _buildTopRow(fontSize, textColor, isDark),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: _categoryGrades.isEmpty
                                    ? _buildEmptyState(fontSize, textColor)
                                    : _buildInsightsGrid(
                                        fontSize, textColor, isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
        bottomNavigationBar: _buildCustomBottomBar(),
      ),
    );
  }

  Widget _buildErrorState(String error, Color? textColor) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(double? fontSize, Color? textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            color: Colors.grey.shade600,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No insights available yet',
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: (fontSize ?? 16) + 1,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Start logging your wellness data to see personalized insights and recommendations.',
            style: TextStyle(
              fontSize: (fontSize ?? 16) - 1,
              color: textColor?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsGrid(double? fontSize, Color? textColor, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Category Breakdown',
          style: TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: (fontSize ?? 16) + 1,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        ..._categoryGrades.entries.map((e) =>
            _buildGradeCard(e.key, e.value, fontSize, textColor, isDark)),
      ],
    );
  }

  Widget _buildTopRow(double? fontSize, Color? textColor, bool isDark) => Row(
        children: [
          Expanded(child: _buildDateRangeCard(fontSize, textColor, isDark)),
          const SizedBox(width: 8),
          Expanded(child: _buildWellnessScoreCard(fontSize, textColor, isDark)),
        ],
      );

  Widget _buildDateRangeCard(double? fontSize, Color? textColor, bool isDark) =>
      Container(
        padding: const EdgeInsets.all(12),
        height: 180,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2B30) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Date Range',
                  style: TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: (fontSize ?? 16) + 1,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                children: [
                  // Top indicator
                  GestureDetector(
                    onTap: () {
                      if (_selectedRange == DateRange.weekly) {
                        _dateRangeController.animateToPage(0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut);
                        _onDateRangeChanged(DateRange.daily);
                      } else if (_selectedRange == DateRange.monthly) {
                        _dateRangeController.animateToPage(1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut);
                        _onDateRangeChanged(DateRange.weekly);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.blue.withOpacity(0.6),
                        size: 16,
                      ),
                    ),
                  ),
                  // Date range selector
                  Expanded(
                    child: ClipRect(
                      child: Builder(
                        builder: (context) => PageView(
                          controller: _dateRangeController,
                          scrollDirection: Axis.vertical,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (index) {
                            final ranges = [
                              DateRange.daily, // Top - Daily
                              DateRange.weekly, // Middle - Weekly
                              DateRange.monthly // Bottom - Monthly
                            ];
                            _onDateRangeChanged(ranges[index]);
                          },
                          children: [
                            _buildDateRangeOption(
                                DateRange.daily,
                                'Daily',
                                fontSize,
                                isDark,
                                _selectedRange == DateRange.daily),
                            _buildDateRangeOption(
                                DateRange.weekly,
                                'Weekly',
                                fontSize,
                                isDark,
                                _selectedRange == DateRange.weekly),
                            _buildDateRangeOption(
                                DateRange.monthly,
                                'Monthly',
                                fontSize,
                                isDark,
                                _selectedRange == DateRange.monthly),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom indicator
                  GestureDetector(
                    onTap: () {
                      if (_selectedRange == DateRange.daily) {
                        _dateRangeController.animateToPage(1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut);
                        _onDateRangeChanged(DateRange.weekly);
                      } else if (_selectedRange == DateRange.weekly) {
                        _dateRangeController.animateToPage(2,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut);
                        _onDateRangeChanged(DateRange.monthly);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.blue.withOpacity(0.6),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildDateRangeOption(DateRange range, String label, double? fontSize,
      bool isDark, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize:
                  isSelected ? (fontSize ?? 16) + 1 : (fontSize ?? 16) - 2,
              color: isSelected
                  ? Colors.blue
                  : (isDark ? Colors.white70 : Colors.black54),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
          if (isSelected) ...[
            const SizedBox(height: 3),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWellnessScoreCard(
          double? fontSize, Color? textColor, bool isDark) =>
      Container(
        padding: const EdgeInsets.all(12),
        height: 180,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2B30) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  color: _gradeColour,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Wellness Score',
                  style: TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: (fontSize ?? 16) + 1,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 70,
              height: 70,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: _overallScore / 100),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, _) => Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 6,
                        backgroundColor: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(_gradeColour),
                      ),
                    ),
                    Text(
                      '$_overallScore%',
                      style: TextStyle(
                        fontFamily: 'HappyMonkey',
                        fontSize: (fontSize ?? 16) + 2,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _gradeColour.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _gradeColour.withOpacity(0.3)),
              ),
              child: Text(
                _getScoreDescription(_overallScore),
                style: TextStyle(
                  fontSize: (fontSize ?? 16) - 2,
                  fontWeight: FontWeight.w600,
                  color: _gradeColour,
                ),
              ),
            ),
          ],
        ),
      );

  String _getScoreDescription(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Work';
  }

  Widget _buildGradeCard(String key, Grade grade, double? fontSize,
      Color? textColor, bool isDark) {
    // Default values if nulls are provided
    final finalFontSize = fontSize ?? 14.0;
    final finalTextColor = textColor ?? Colors.black;

    // Define styling based on grade
    Color cardColor;
    Color iconColor;
    IconData icon;
    String emoji;

    switch (grade) {
      case Grade.green:
        cardColor = isDark ? const Color(0xFF2ECC71) : const Color(0xFFB6FFB1);
        iconColor = Colors.green.shade700;
        icon = _getCategoryIcon(key);
        emoji = '😊';
        break;
      case Grade.amber:
        cardColor = isDark ? const Color(0xFFF4D03F) : const Color(0xFFFFDC75);
        iconColor = Colors.orange.shade700;
        icon = _getCategoryIcon(key);
        emoji = '😐';
        break;
      case Grade.red:
        cardColor = isDark ? const Color(0xFFE74C3C) : const Color(0xFFFF8A7D);
        iconColor = Colors.red.shade700;
        icon = _getCategoryIcon(key);
        emoji = '😞';
        break;
    }

    return Container(
      key: ValueKey('grade_card_$key'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon on the left
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          // Text label in the middle
          Expanded(
            child: Text(
              _pretty(key),
              style: TextStyle(
                fontFamily: 'HappyMonkey',
                fontSize: finalFontSize + 1,
                fontWeight: FontWeight.w600,
                color: finalTextColor,
              ),
            ),
          ),
          // Emoji on the right
          Text(
            emoji,
            style: TextStyle(
              fontSize: finalFontSize + 4,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String key) {
    switch (key) {
      case 'sleep_bucket':
      case 'sleep':
      case 'sleep_quality':
        return Icons.nights_stay_outlined; // Crescent moon for sleep
      case 'hydration_bucket':
      case 'hydration':
        return Icons.water_drop_outlined; // Water drop for hydration
      case 'exercise_bucket':
      case 'exercise':
        return Icons.fitness_center_outlined; // Dumbbell for exercise
      case 'mindfulness_activities':
      case 'mindfulness':
        return Icons.psychology_outlined; // Brain icon for mindfulness
      case 'diet':
        return Icons.restaurant_menu_outlined; // Fork and knife for diet
      default:
        return Icons.help_outline; // Fallback icon for unknown categories
    }
  }

  Widget _buildCustomBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
        ],
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

  Widget _buildNavItem(
      {required IconData icon, required int index, bool isHome = false}) {
    final isSelected = (_selectedIndex == index);
    final fillColor = isSelected
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
          setState(() => _selectedIndex = index);
          if (index == 0) {
            Navigator.pushReplacement(
                context, createFadeRoute(const SettingsScreen()));
          }
          if (index == 1) {
            Navigator.pushReplacement(
                context, createFadeRoute(const InsightsScreen()));
          }
          if (index == 2) {
            Navigator.pushReplacement(
                context, createFadeRoute(const HomeScreen()));
          }
          if (index == 3) {
            Navigator.pushReplacement(
                context, createFadeRoute(const ActivitiesScreen()));
          }
          if (index == 4) {
            Navigator.pushReplacement(
                context, createFadeRoute(const ProfileScreen()));
          }
        },
        child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(shape: BoxShape.circle, color: fillColor),
            child: Icon(icon, color: iconColor)),
      ),
    );
  }
}
