import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mindshed_app/home_screen.dart';
import 'package:mindshed_app/settings_screen.dart';
import 'package:mindshed_app/activities_screen.dart';
import 'package:mindshed_app/profile_screen.dart';
import 'package:mindshed_app/transition_helper.dart';
import 'package:mindshed_app/new_insights_engine.dart'
    show DateRange, Grade, NewInsightsEngine;
import 'shared_navigation.dart';
import 'shared_ui_components.dart';

const cream = Color(0xFFFFF9DA);
const mint = Color(0xFFB6FFB1);

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 1;
  DateRange _selectedRange = DateRange.daily;

  double _overallScore = 0.0;
  Color _gradeColour = Colors.grey;

  Map<String, Grade> _categoryGrades = {};

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  late Box _metricsBox;

  bool _isLoading = false;
  String? _error;
  NewInsightsEngine? _engine;

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
      .map(
        (w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
      )
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
        _engine = NewInsightsEngine(_metricsBox);
        await _engine!.initialize();
      }

      final score = await _engine!.getWellnessScore(userId, _selectedRange);
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

  // Updated category mapping for 8 categories
  String _pretty(String category) {
    switch (category) {
      case 'sleep_health':
        return 'Sleep Health';
      case 'cardiovascular':
        return 'Cardiovascular';
      case 'physical_activity':
        return 'Physical Activity';
      case 'consistency_habits':
        return 'Consistency & Habits';
      case 'recovery_stress':
        return 'Recovery & Stress';
      case 'social_wellness':
        return 'Social Wellness';
      case 'nutrition_hydration':
        return 'Nutrition & Hydration';
      case 'mental_wellness':
        return 'Mental Wellness';
      default:
        return _capitalizeWords(category.replaceAll('_', ' '));
    }
  }

  // NEW: Check if category needs multi-day data
  bool _needsMultiDayData(String category) {
    return [
      'sleep_health',
      'consistency_habits',
      'recovery_stress',
      'social_wellness',
    ].contains(category);
  }

  // NEW: Get date range label
  String _getDateRangeLabel(DateRange range) {
    switch (range) {
      case DateRange.daily:
        return 'Daily';
      case DateRange.weekly:
        return 'Weekly';
      case DateRange.monthly:
        return 'Monthly';
      case DateRange.overall:
        return 'Overall';
    }
  }

  // Updated icon mapping for 8 categories
  IconData _getCategoryIconData(String category) {
    switch (category) {
      case 'sleep_health':
        return Icons.bedtime_outlined;
      case 'cardiovascular':
        return Icons.favorite_outline;
      case 'physical_activity':
        return Icons.directions_run_outlined;
      case 'consistency_habits':
        return Icons.repeat_outlined;
      case 'recovery_stress':
        return Icons.spa_outlined;
      case 'social_wellness':
        return Icons.people_outline;
      case 'nutrition_hydration':
        return Icons.local_drink_outlined;
      case 'mental_wellness':
        return Icons.psychology_outlined;
      default:
        return Icons.health_and_safety_outlined;
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
              ? [const Color(0xFF1C1D22), const Color(0xFF2A2B30)]
              : [const Color(0xFFE8E8E8), Colors.white],
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Scaffold(
        backgroundColor: cream,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildErrorState(_error!, textColor)
            : SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          SharedUIComponents.buildHeaderPill(
                            'Wellness Insights',
                            fontSize: (fontSize ?? 18) + 4,
                          ),
                          const SizedBox(height: 18),
                          _buildTopRow(fontSize, textColor, isDark),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Stack(
                          children: [
                            SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 60),
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: _categoryGrades.isEmpty
                                      ? _buildEmptyState(fontSize, textColor)
                                      : _buildInsightsGrid(
                                          fontSize,
                                          textColor,
                                          isDark,
                                        ),
                                ),
                              ),
                            ),
                            // Fade out gradient at bottom
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 60,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      cream.withOpacity(0.0),
                                      cream.withOpacity(0.8),
                                      cream,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: SharedNavigation.buildBottomNavigation(
          selectedIndex: _selectedIndex,
          context: context,
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, Color? textColor) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Category Breakdown',
          style: TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: (fontSize ?? 16) + 1,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(top: 8),
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
        ),
      ],
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
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        ..._categoryGrades.entries.map(
          (e) => _buildGradeCard(e.key, e.value, fontSize, textColor, isDark),
        ),
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

  Widget _buildDateRangeCard(
    double? fontSize,
    Color? textColor,
    bool isDark,
  ) => Container(
    padding: const EdgeInsets.all(12),
    height: 180,
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF2A2B30) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black26 : Colors.black12,
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
      border: Border.all(
        color: isDark ? Colors.white10 : Colors.black,
        width: isDark ? 1 : 2,
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              'Date Range',
              style: TextStyle(
                fontFamily: 'HappyMonkey',
                fontSize: (fontSize ?? 16) + 1,
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
                    _onDateRangeChanged(DateRange.daily);
                  } else if (_selectedRange == DateRange.monthly) {
                    _onDateRangeChanged(DateRange.weekly);
                  } else if (_selectedRange == DateRange.overall) {
                    _onDateRangeChanged(DateRange.monthly);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.lightBlue,
                    size: 16,
                  ),
                ),
              ),
              // Date range selector
              Expanded(
                child: Center(
                  child: _buildDateRangeOption(
                    _selectedRange,
                    _getDateRangeLabel(_selectedRange),
                    fontSize,
                    isDark,
                    true, // Always selected since this is the current selection
                  ),
                ),
              ),
              // Bottom indicator
              GestureDetector(
                onTap: () {
                  if (_selectedRange == DateRange.daily) {
                    _onDateRangeChanged(DateRange.weekly);
                  } else if (_selectedRange == DateRange.weekly) {
                    _onDateRangeChanged(DateRange.monthly);
                  } else if (_selectedRange == DateRange.monthly) {
                    _onDateRangeChanged(DateRange.overall);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.lightBlue,
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

  Widget _buildDateRangeOption(
    DateRange range,
    String label,
    double? fontSize,
    bool isDark,
    bool isSelected,
  ) {
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
              fontSize: isSelected
                  ? (fontSize ?? 16) + 1
                  : (fontSize ?? 16) - 2,
              color: isSelected
                  ? Colors.blue
                  : (isDark ? Colors.white70 : Colors.black54),
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
    double? fontSize,
    Color? textColor,
    bool isDark,
  ) => Container(
    padding: const EdgeInsets.all(12),
    height: 180,
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF2A2B30) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black26 : Colors.black12,
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
      border: Border.all(
        color: isDark ? Colors.white10 : Colors.black,
        width: isDark ? 1 : 2,
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Icon(Icons.favorite_rounded, color: _gradeColour, size: 20),
            const SizedBox(width: 8),
            Text(
              'Wellness Score',
              style: TextStyle(
                fontFamily: 'HappyMonkey',
                fontSize: (fontSize ?? 16) > 20 ? 18 : (fontSize ?? 16) + 1,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
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
                  '${_overallScore.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: (fontSize ?? 16) > 20 ? 16 : (fontSize ?? 16),
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_overallScore > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _gradeColour.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _gradeColour),
            ),
            child: Text(
              _getScoreDescription(_overallScore),
              style: TextStyle(
                fontSize: (fontSize ?? 16) > 20 ? 14 : (fontSize ?? 16) - 2,
                color: _gradeColour,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey),
            ),
            child: Text(
              'No Data',
              style: TextStyle(
                fontSize: (fontSize ?? 16) > 20 ? 14 : (fontSize ?? 16) - 2,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    ),
  );

  String _getScoreDescription(double score) {
    if (score == 0) return 'No Data';
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Work';
  }

  Widget _buildGradeCard(
    String key,
    Grade grade,
    double? fontSize,
    Color? textColor,
    bool isDark,
  ) {
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
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: iconColor, width: 1),
      ),
      child: Row(
        children: [
          // Icon on the left
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          // Text label in the middle
          Expanded(
            child: Text(
              _pretty(key),
              style: TextStyle(
                fontFamily: 'HappyMonkey',
                fontSize: finalFontSize + 1,
                color: finalTextColor,
              ),
            ),
          ),
          // Emoji on the right
          Text(emoji, style: TextStyle(fontSize: finalFontSize + 4)),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'sleep_health':
        return Icons.bedtime_outlined;
      case 'cardiovascular':
        return Icons.favorite_outline;
      case 'physical_activity':
        return Icons.directions_run_outlined;
      case 'consistency_habits':
        return Icons.repeat_outlined;
      case 'recovery_stress':
        return Icons.spa_outlined;
      case 'social_wellness':
        return Icons.people_outline;
      case 'nutrition_hydration':
        return Icons.local_drink_outlined;
      case 'mental_wellness':
        return Icons.psychology_outlined;
      default:
        return Icons.health_and_safety_outlined;
    }
  }
}
