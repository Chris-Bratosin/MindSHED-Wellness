import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'insights_engine.dart';
import 'health_data_models.dart'; // DateRange
import 'pet_selection.dart';
import 'pet_list_screen.dart';

/// Safe SVG (won’t crash if asset missing/empty).
class SafeSvg extends StatelessWidget {
  const SafeSvg(this.asset, {super.key, this.width, this.height, this.fit = BoxFit.contain});
  final String? asset;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final a = asset;
    if (a == null || a.isEmpty) return const Icon(Icons.pets, size: 56);
    return FutureBuilder<String>(
      future: DefaultAssetBundle.of(context).loadString(a),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            width: 40,
            height: 40,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snap.hasError || !(snap.hasData) || snap.data!.trim().isEmpty) {
          return const Icon(Icons.pets, size: 56);
        }
        return SvgPicture.string(
          snap.data!,
          key: ValueKey(a),
          width: width,
          height: height,
          fit: fit,
        );
      },
    );
  }
}

class PetPanel extends StatefulWidget {
  const PetPanel({super.key});
  @override
  State<PetPanel> createState() => _PetPanelState();
}

class _PetPanelState extends State<PetPanel> {
  String _username = '';
  String? _petName;
  String _petMood = 'Normal';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final sessionBox = Hive.box('session');
    final metricsBox = Hive.box('dailyMetrics');
    final petBox = Hive.box('petNames');
    final userId = sessionBox.get('loggedInUser') as String?;
    if (userId != null) {
      final storedPetName = petBox.get(userId) as String?;
      final engine = InsightsEngine(metricsBox);
      final score = await engine.getPredictedScore(userId, DateRange.daily);
      String mood = 'Normal';
      if (score >= 80) {
        mood = 'Excited';
      } else if (score >= 60) {
        mood = 'Happy';
      } else if (score >= 40) {
        mood = 'Okay';
      } else if (score >= 20) {
        mood = 'Tired';
      } else if (score > 0) {
        mood = 'Sad';
      }
      if (mounted) {
        setState(() {
          _username = userId;
          _petName = storedPetName;
          _petMood = score == 0 ? 'Normal' : mood;
        });
      }
    }
  }

  Future<void> _renamePet() async {
    final controller = TextEditingController(text: _petName ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Your Pet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter pet name'),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _petName) {
      final sessionBox = Hive.box('session');
      final petBox = Hive.box('petNames');
      final userId = sessionBox.get('loggedInUser') as String?;
      if (userId != null) {
        await petBox.put(userId, newName);

        // tiny XP reward (optional)
        final xpKey = '${userId}_totalXp';
        final currentXp = sessionBox.get(xpKey) as int? ?? 0;
        await sessionBox.put(xpKey, currentXp + 10);

        if (mounted) setState(() => _petName = newName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pet name set to "$newName"')),
          );
        }
      }
    }
  }

  Future<void> _openPetList() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PetListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Style tokens to match your app
    const mint = Color(0xFFB6FFB1); // soft green you’re using
    const border2 = BorderSide(color: Colors.black, width: 2);
    final radiusCard = BorderRadius.circular(22);
    final radiusPill = BorderRadius.circular(12);

    Widget pill(String text, {VoidCallback? onTap}) {
      final child = Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: radiusPill,
          border: const Border.fromBorderSide(border2),
        ),
        child: Text(text, style: theme.textTheme.titleMedium),
      );
      return onTap == null
          ? child
          : InkWell(onTap: onTap, borderRadius: radiusPill, child: child);
    }

    return ValueListenableBuilder<String>(
      valueListenable: PetSelection.instance.selectedId,
      builder: (context, selectedId, _) {
        final asset = petAssetFor(selectedId);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: radiusCard,
            border: const Border.fromBorderSide(border2),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Pet avatar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: asset == null
                          ? const Center(child: Icon(Icons.pets, size: 44))
                          : SafeSvg(asset),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Right column with two pills
                  Expanded(
                    child: Column(
                      children: [
                        // Top pill = current name (tap to rename)
                        pill(
                          (_petName != null && _petName!.trim().isNotEmpty)
                              ? _petName!
                              : 'Set your pet name',
                          onTap: _renamePet,
                        ),
                        const SizedBox(height: 10),
                        // Second pill = mood (read-only)
                        pill('Mood: $_petMood'),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Select Pet button (mint fill + black outline)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _openPetList,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(mint),
                    side: MaterialStateProperty.all(border2),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 14),
                    ),
                    foregroundColor: MaterialStateProperty.all(Colors.black),
                    textStyle: MaterialStateProperty.all(
                      theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  child: const Text('Select Pet'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
