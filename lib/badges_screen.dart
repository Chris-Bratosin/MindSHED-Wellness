import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});
  @override
  _BadgesScreenState createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> with WidgetsBindingObserver {
  // ---- palette (mockup) ----
  static const cream = Color(0xFFFFF9DA);
  static const mintCard = Color(0xFFD6F5D6);
  static const mintPill = Color(0xFFE6F6D8);
  static const rowMint = Color(0xFFEAFCE6);
  static const blueBar = Color(0xFF78AEEA);

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
    if (state == AppLifecycleState.resumed) _loadData();
  }

  // --------- SAME LOGIC AS BEFORE ---------
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
  // ----------------------------------------

  // ---- UI helpers ----
  Widget _headerPill(String text) => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Text(text, style: const TextStyle(fontFamily: 'HappyMonkey', fontSize: 24, color: Colors.black)),
    ),
  );

  BoxDecoration _cardBox() => BoxDecoration(
    color: mintCard,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.black, width: 2),
  );

  Widget _mintChip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: mintPill,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.black, width: 2),
    ),
    child: Text(text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontFamily: 'HappyMonkey', fontWeight: FontWeight.w600, color: Colors.black),
    ),
  );

  Widget _backButton() => Center(
    child: Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.maybePop(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFB6FFB1),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: const Text('Back', style: TextStyle(fontFamily: 'HappyMonkey', fontWeight: FontWeight.w700, color: Colors.black)),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext ctx) {
    final size  = Theme.of(ctx).textTheme.bodyMedium?.fontSize ?? 14.0;

    const xpForLevel = 100;
    final level    = _totalXp ~/ xpForLevel + 1;
    final within   = (_totalXp % xpForLevel); // xp within current level
    final progress = within / xpForLevel;

    // SAME ACHIEVEMENT LOGIC, just styled differently
    final achievements = [
      {
        'title': 'Finally named my pet!',
        'desc':  'You gave your pet a name.',
        'xp':    10,
        'unlocked': (_petName ?? '').isNotEmpty,
      },
      {
        'title': '3-Day Streak',
        'desc':  'Logged in 3 days straight.',
        'xp':    5,
        'unlocked': _streak >= 3,
      },
      {
        'title': '7-Day Streak',
        'desc':  'Logged in 7 days straight.',
        'xp':    10,
        'unlocked': _streak >= 7,
      },
    ];
    final totalBadges = achievements.where((b) => b['unlocked'] as bool).length;

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cream,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        title: Text('View Badges', style: TextStyle(fontFamily: 'HappyMonkey', fontSize: size, color: Colors.black)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          children: [
            _headerPill('Badges'),
            const SizedBox(height: 12),

            // Top stat card (avatar + two chips + progress)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: _cardBox(),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: const Icon(Icons.person, size: 48, color: Colors.black),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _mintChip('Total Badges: $totalBadges'),
                            const SizedBox(height: 8),
                            _mintChip('User Level: $level'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$within/$xpForLevel',
                      style: const TextStyle(fontFamily: 'HappyMonkey', color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 16,
                        color: blueBar,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            // Achievements header pill
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: mintCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Center(
                child: Text('Your Achievements',
                    style: TextStyle(fontFamily: 'HappyMonkey', fontSize: size + 2, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ),

            const SizedBox(height: 10),
            // Achievement rows (UI-only change)
            ...achievements.map((b) {
              final ok = b['unlocked'] as bool;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: rowMint,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // left medal tile
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: const Icon(Icons.military_tech_outlined, size: 24, color: Colors.black),
                      ),
                      const SizedBox(width: 12),
                      // text column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b['title'] as String,
                                style: TextStyle(
                                  fontFamily: 'HappyMonkey',
                                  fontSize: size + 2,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                )),
                            const SizedBox(height: 2),
                            Text(b['desc'] as String,
                                style: TextStyle(
                                  fontFamily: 'HappyMonkey',
                                  fontSize: size,
                                  color: Colors.black,
                                )),
                            const SizedBox(height: 2),
                            Text('+${b['xp']}xp',
                                style: TextStyle(
                                  fontFamily: 'HappyMonkey',
                                  fontSize: size - 2,
                                  color: Colors.black,
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(ok ? Icons.emoji_events_outlined : Icons.lock_outline, size: 26, color: Colors.black),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),
            _backButton(),
          ],
        ),
      ),
    );
  }
}
