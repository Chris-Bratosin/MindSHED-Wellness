import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'pet_selection.dart';

const cream = Color(0xFFFFF9DA);

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class SafeSvg extends StatelessWidget {
  const SafeSvg(
    this.asset, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });
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
        if (snap.data!.trim().isEmpty || snap.hasError || !(snap.hasData)) {
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

class PetInfo {
  final String id;
  final String title;
  final String blurb;
  final bool locked;

  const PetInfo(this.id, this.title, this.blurb, {this.locked = false});
  const PetInfo.locked(this.id)
    : title = 'Locked',
      blurb = 'This pet is currently locked.',
      locked = true;
}

// Descriptions (edit as you like).
const _pets = <PetInfo>[
  PetInfo(
    'flare',
    'Flare',
    'Flare is a small, fiery dragon who thrives on positive energy. Despite its flames, it radiates warmth and encouragement. '
        'As you progress on your wellness journey, Flare becomes brighter and stronger, mirroring your self-care habits. '
        'This loyal companion celebrates your achievements with cheerful animations and motivational messages, while offering gentle reminders to help you stay on track when your wellness dips.',
  ),
  PetInfo(
    'pebble',
    'Pebble',
    'Pebble is a gentle, playful penguin who brings calm wherever it goes. Cool and collected, Pebble helps you stay balanced on your wellness journey. '
        'As you take care of yourself, Pebble becomes more cheerful and animated, reflecting your progress. '
        'This loyal companion celebrates your milestones with happy waddles and encouraging messages, while offering soft reminders to help you stay steady when life feels overwhelming.',
  ),
  PetInfo(
    'koda',
    'Koda',
    'Koda is a cheerful, energetic pup who thrives on activity and positivity. Always ready to wag its tail, Koda motivates you to keep moving and stay engaged with your wellness goals. '
        'As you complete tasks and log your progress, Koda becomes more playful and lively, rewarding your efforts with joyful animations and uplifting barks. '
        'When your motivation dips, Koda offers friendly nudges to help you get back on track with a smile.',
  ),
  PetInfo(
    'plumping',
    'Plumping',
    'Plumpling is a soft, sprout-topped creature that embodies calmness and steady growth. With its soothing presence, Plumpling encourages you to nurture yourself day by day, reminding you that small steps lead to big changes. '
        'As you care for your wellness, Plumpling’s leaves grow brighter and its energy blossoms, celebrating your progress with gentle animations and kind words. '
        'When you need support, it offers quiet encouragement to help you keep moving forward.',
  ),
  PetInfo.locked('locked1'),
  PetInfo.locked('locked2'),
];

class PetListScreen extends StatelessWidget {
  const PetListScreen({super.key, this.currentUsername});
  final String? currentUsername;

  String _resolveUsername() {
    final session = Hive.box('session');
    final u = (session.get('loggedInUser') as String?);
    if (currentUsername != null && currentUsername!.trim().isNotEmpty) {
      return currentUsername!;
    }
    if (u != null && u.trim().isNotEmpty) return u;
    return 'Friend';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final username = _resolveUsername();

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pets'),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _pets.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: .85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final pet = _pets[index];
          final asset = petAssetFor(pet.id);
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _openSheet(context, pet, username),
            child: Ink(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (asset != null)
                    SafeSvg(asset, width: 120, height: 120)
                  else
                    Icon(
                      pet.locked ? Icons.lock_outline : Icons.pets,
                      size: 60,
                    ),
                  const SizedBox(height: 8),
                  Text(pet.title, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openSheet(BuildContext context, PetInfo pet, String username) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _PetSheet(pet: pet, username: username),
    );
  }
}

class _PetSheet extends StatelessWidget {
  const _PetSheet({required this.pet, required this.username});
  final PetInfo pet;
  final String username;

  @override
  Widget build(BuildContext context) {
    final prefs = Hive.box('prefs');
    final sinceKey = 'friendSince:${username}_${pet.id}';
    final int? sinceMs = prefs.get(sinceKey) as int?;
    final DateTime sinceDate = sinceMs != null
        ? DateTime.fromMillisecondsSinceEpoch(sinceMs)
        : DateTime.now();
    final String sinceLabel = _fmtDate(sinceDate);

    final theme = Theme.of(context);
    final asset = petAssetFor(pet.id);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(pet.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),

            if (asset != null)
              SafeSvg(asset, width: 140, height: 140)
            else
              Icon(pet.locked ? Icons.lock_outline : Icons.pets, size: 72),

            const SizedBox(height: 16),

            if (!pet.locked)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Text(
                  'Friends with $username since: $sinceLabel',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),

            const SizedBox(height: 16),

            Text(
              pet.blurb,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 20),

            if (!pet.locked)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await PetSelection.instance.setSelected(pet.id);

                    if (prefs.get(sinceKey) == null) {
                      await prefs.put(
                        sinceKey,
                        DateTime.now().millisecondsSinceEpoch,
                      );
                    }

                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      const Color(0xFFFFF9DA),
                    ), // mint
                    side: MaterialStateProperty.all(
                      const BorderSide(color: Colors.black, width: 2),
                    ),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    foregroundColor: MaterialStateProperty.all(Colors.black),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 14),
                    ),
                    textStyle: MaterialStateProperty.all(
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  child: Text('Choose ${pet.title}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
