import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});
  @override
  _BadgesScreenState createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> with WidgetsBindingObserver {
  String? _petName;
  int _streak  = 0;
  int _totalXp = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final session = await Hive.openBox('session');
    final pets    = await Hive.openBox('petNames');
    final userId  = session.get('loggedInUser') as String?;
    if (userId == null) return;

    setState(() {
      _petName = pets.get(userId) as String?;
      _streak  = session.get('${userId}_currentStreak') as int? ?? 0;
      _totalXp = session.get('${userId}_totalXp') as int? ?? 0;
    });
  }

  @override
  Widget build(BuildContext ctx) {
    final theme    = Theme.of(ctx);
    final color    = theme.textTheme.bodyMedium?.color;
    final size     = theme.textTheme.bodyMedium?.fontSize ?? 14.0;
    final subtitle = theme.textTheme.bodyMedium?.copyWith(color: color);
    final caption  = theme.textTheme.bodySmall?.copyWith(color: color);

    const xpForLevel = 100;
    final level    = _totalXp ~/ xpForLevel + 1;
    final progress = (_totalXp % xpForLevel) / xpForLevel;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: color),
          onPressed: () => Navigator.pop(ctx),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('View Badges',
          style: TextStyle(fontFamily: 'HappyMonkey', fontSize: size, color: color),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2C2F36)
                    : const Color(0xFFD6F5D6),
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, size: 50),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildMiniBox(ctx, "Total XP: $_totalXp", subtitle),
                        const SizedBox(height: 8),
                        _buildXpBar(ctx, _totalXp, level, progress, size, color),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2C2F36)
                    : const Color(0xFFE6FFE6),
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(child: Text(
                'Your Achievements',
                style: TextStyle(
                  fontFamily: 'HappyMonkey',
                  fontSize: size + 2,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              )),
            ),

            const SizedBox(height: 8),
            ...[
              {
                'title': 'Finally named my pet!',
                'desc': 'You gave your pet a name.',
                'xp': 10,
                'unlocked': (_petName ?? '').isNotEmpty,
              },
              {
                'title': '3-Day Streak',
                'desc': 'Logged in 3 days straight.',
                'xp': 5,
                'unlocked': _streak >= 3,
              },
              {
                'title': '7-Day Streak',
                'desc': 'Logged in 7 days straight.',
                'xp': 10,
                'unlocked': _streak >= 7,
              },
            ].map((b) {
              final ok = b['unlocked'] as bool;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2C2F36)
                      : const Color(0xFFE6FFE6),
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(ok ? Icons.emoji_events : Icons.lock_outline, size: 36),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b['title'] as String,
                          style: subtitle?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(b['desc'] as String, style: subtitle),
                        Text('+${b['xp']}xp', style: caption),
                      ],
                    )),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

Widget _buildMiniBox(BuildContext context, String text, TextStyle? style) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF3A3D44)
          : const Color(0xFFCCFFCC),
      border: Border.all(color: Colors.black, width: 2),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Center(child: Text(text, style: style)),
  );
}

Widget _buildXpBar(BuildContext context, int xp, int level, double progress, double fontSize, Color? textColor) {
  return Stack(
    alignment: Alignment.center,
    children: [
      Container(
        height: 24,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white, minHeight: 24),
        ),
      ),
      Text(
        'Level $level   $xp/${level * 100} xp',
        style: TextStyle(
          fontFamily: 'HappyMonkey',
          fontSize: fontSize * 0.9,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}