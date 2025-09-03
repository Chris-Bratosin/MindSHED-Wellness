import 'package:flutter/material.dart';

class SharedUIComponents {
  // ====== COLORS ======
  static const Color cream = Color(0xFFFFF9DA);
  static const Color mint = Color(0xFFB6FFB1);
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color grey800 = Color(0xFF424242);

  // ====== SPACING ======
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing18 = 18.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing28 = 28.0;

  // ====== BORDER RADIUS ======
  static const double borderRadius12 = 12.0;
  static const double borderRadius16 = 16.0;
  static const double borderRadius18 = 18.0;
  static const double borderRadius22 = 22.0;

  // ====== SHADOWS ======
  static const List<BoxShadow> standardShadow = [
    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
  ];

  static const List<BoxShadow> subtleShadow = [
    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
  ];

  // ====== HEADER PILL ======
  static Widget buildHeaderPill(String text, {double? fontSize}) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(borderRadius18),
          border: Border.all(color: black, width: 2),
          boxShadow: standardShadow,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'HappyMonkey',
            fontWeight: FontWeight.w600,
            fontSize: fontSize ?? 24,
            color: black,
          ),
        ),
      ),
    );
  }

  // ====== STANDARD CARD ======
  static Widget buildCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(spacing16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(borderRadius ?? borderRadius18),
        border: Border.all(color: black, width: 2),
        boxShadow: standardShadow,
      ),
      child: child,
    );
  }

  // ====== MINT ACTION BUTTON ======
  static Widget buildMintActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    double? fontSize,
    bool twoLine = false,
  }) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius18),
        side: const BorderSide(color: black, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing16,
            vertical: spacing16,
          ),
          decoration: BoxDecoration(
            color: mint,
            borderRadius: BorderRadius.circular(borderRadius18),
            boxShadow: standardShadow,
          ),
          child: Row(
            children: [
              Icon(icon, color: black, size: 28),
              const SizedBox(width: spacing12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: (fontSize ?? 16) + 2,
                    color: black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====== MINT BUTTON (COMPACT) ======
  static Widget buildMintButton({
    required String label,
    required VoidCallback onTap,
    IconData? icon,
    double? fontSize,
  }) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius22),
        side: const BorderSide(color: black, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: spacing20,
            vertical: spacing12,
          ),
          decoration: BoxDecoration(
            color: mint,
            borderRadius: BorderRadius.circular(borderRadius22),
            boxShadow: subtleShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: black),
                const SizedBox(width: spacing8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'HappyMonkey',
                  color: black,
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====== LABEL CHIP ======
  static Widget buildLabelChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(borderRadius18),
        border: Border.all(color: black, width: 1.6),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'HappyMonkey', color: black),
      ),
    );
  }

  // ====== ACTIVITY BUTTON ======
  static Widget buildActivityButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool twoLine = false,
    Color? backgroundColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: twoLine ? 96 : 78,
        padding: const EdgeInsets.symmetric(
          horizontal: spacing20,
          vertical: spacing16,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? white,
          borderRadius: BorderRadius.circular(borderRadius18),
          border: Border.all(color: black, width: 2),
          boxShadow: standardShadow,
        ),
        child: Row(
          children: [
            Icon(icon, color: black, size: 32),
            const SizedBox(width: spacing16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'HappyMonkey',
                  fontSize: 18,
                  color: black,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: black, size: 20),
          ],
        ),
      ),
    );
  }

  // ====== SCREEN LAYOUT ======
  static Widget buildScreenLayout({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: ListView(
          padding:
              padding ??
              const EdgeInsets.fromLTRB(
                spacing16,
                spacing12,
                spacing16,
                spacing24,
              ),
          children: [child],
        ),
      ),
    );
  }

  // ====== TASK ITEM ======
  static Widget buildTaskItem({
    required String title,
    required Color color,
    required bool isChecked,
    required VoidCallback onTap,
    bool isAnimating = false,
  }) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: isAnimating ? 0 : 1,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: spacing8),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadius18),
            border: Border.all(color: black, width: 2),
            boxShadow: standardShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: 16,
                    color: black,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: white,
                    border: Border.all(color: black, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: AnimatedOpacity(
                    opacity: isChecked ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.check, size: 18, color: black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====== ADD BUTTON ======
  static Widget buildAddButton(VoidCallback onTap) {
    return Center(
      child: InkWell(
        onTap: onTap,
        child: Material(
          elevation: 3,
          shape: const CircleBorder(side: BorderSide(color: black, width: 2)),
          child: Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: white,
            ),
            child: const Icon(Icons.add, size: 30, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
