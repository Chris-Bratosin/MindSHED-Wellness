import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Preference keys
const String kSelectedPetIdKey = 'selected_pet_id';
const String kPetNameKey = 'pet_name';
const String kUsernameKey = 'username';

// Map ids to actual asset filenames (case-sensitive, matches pubspec)
const Map<String, String> kPetAsset = {
  'flare': 'assets/pets/flare.svg',
  'pebble': 'assets/pets/pebble.svg',
  'koda': 'assets/pets/koda.svg',
  'plumping': 'assets/pets/plumping.svg',
};

String? petAssetFor(String id) => kPetAsset[id];

class PetSelection {
  PetSelection._();
  static final PetSelection instance = PetSelection._();

  /// Current selected pet id. Listen to this to rebuild UI instantly.
  final ValueNotifier<String> selectedId = ValueNotifier<String>('flare');

  /// Call once before runApp().
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    selectedId.value = prefs.getString(kSelectedPetIdKey) ?? 'flare';
  }

  Future<void> setSelected(String id) async {
    if (id == selectedId.value) return;
    selectedId.value = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kSelectedPetIdKey, id);
  }
}
