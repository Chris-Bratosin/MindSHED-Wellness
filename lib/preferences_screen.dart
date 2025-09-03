import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'main.dart'; // to access themeNotifier
import 'shared_ui_components.dart';

const cream = Color(0xFFFFF9DA);

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool isDarkTheme = false;
  bool showQuotes = true;
  String fontSize = 'Normal';

  @override
  void initState() {
    super.initState();
    final prefs = Hive.box('prefs');
    isDarkTheme = prefs.get('darkMode', defaultValue: false);
    fontSize = prefs.get('fontSize', defaultValue: 'Normal');
  }

  @override
  Widget build(BuildContext context) {
    final currentFontSize =
        Theme.of(context).textTheme.bodyMedium?.fontSize ?? 18;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SharedUIComponents.buildHeaderPill(
                'Preferences',
                fontSize: currentFontSize + 4,
              ),
              const SizedBox(height: 18),

              // 1. Dark Theme Toggle
              _buildSwitchTile(
                title: 'Dark Theme',
                value: isDarkTheme,
                onChanged: (val) async {
                  setState(() {
                    isDarkTheme = val;
                  });
                  final prefs = Hive.box('prefs');
                  await prefs.put('darkMode', val);
                  themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                },
              ),

              const SizedBox(height: 16),

              // 2. Font Size Selection
              _buildFontSizeSelector(currentFontSize),

              const SizedBox(height: 16),

              // 3. App Themes Selection (Locked)
              _buildAppThemesSelector(currentFontSize),

              const SizedBox(height: 16),

              // 4. App Animations Toggle
              _buildSwitchTile(
                title: 'App Animations',
                value: false, // Placeholder value
                onChanged: (val) {
                  // Placeholder logic
                },
              ),

              const SizedBox(height: 16),

              // 5. Face ID Access Toggle
              _buildSwitchTile(
                title: 'Face ID Access',
                value: false, // Placeholder value
                onChanged: (val) {
                  // Placeholder logic
                },
              ),

              const Spacer(),
              const SizedBox(height: 20),
              _backButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final currentFontSize =
        Theme.of(context).textTheme.bodyMedium?.fontSize ?? 18;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: currentFontSize,
              color: Colors.black87,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFB6FFB1), // Light green
            inactiveThumbColor: Colors.grey.shade600,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _backButton() => Center(
    child: Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 120,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFB6FFB1),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'Back',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildFontSizeSelector(double currentFontSize) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Font Size',
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: currentFontSize,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['Small', 'Medium', 'Large'].map((size) {
              bool isSelected =
                  fontSize == size ||
                  (fontSize == 'Normal' && size == 'Medium');
              return InkWell(
                onTap: () async {
                  setState(() {
                    fontSize = size;
                  });
                  final prefs = Hive.box('prefs');
                  await prefs.put('fontSize', size);
                  fontSizeNotifier.value = size;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFB6FFB1) // Light green for selected
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Text(
                    size,
                    style: TextStyle(
                      fontFamily: 'HappyMonkey',
                      fontSize: currentFontSize - 2,
                      color: Colors.black87,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppThemesSelector(double currentFontSize) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Themes',
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: currentFontSize,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['Spring', 'Summer', 'Winter'].map((theme) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      theme,
                      style: TextStyle(
                        fontFamily: 'HappyMonkey',
                        fontSize: currentFontSize - 2,
                        color: Colors.black87,
                      ),
                    ),
                    // Diagonal line crossing through the button to show it's locked
                    Positioned.fill(
                      child: CustomPaint(painter: DiagonalLinePainter()),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Unlock with XP!',
              style: TextStyle(
                fontFamily: 'HappyMonkey',
                fontSize: currentFontSize - 2,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for drawing diagonal lines through locked theme buttons
class DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.red.shade400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw diagonal line from top-left to bottom-right
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), linePaint);

    // Draw diagonal line from top-right to bottom-left
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
