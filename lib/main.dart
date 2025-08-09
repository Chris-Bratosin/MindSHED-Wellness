import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'user.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'notification_service.dart';

ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
ValueNotifier<String> fontSizeNotifier = ValueNotifier('normal');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);

  Hive.registerAdapter(UserAdapter());
  await Hive.openBox<User>('users');
  await Hive.openBox('session');
  await Hive.openBox('prefs');

  final encryptionKey = await _getEncryptionKey();
  await Hive.openBox(
    'dailyMetrics',
    encryptionCipher: HiveAesCipher(encryptionKey),
  );

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/London'));

  await NotificationService.init();
  await NotificationService.scheduleDailyReminder();

  final sessionBox = Hive.box('session');
  final rememberedUser = sessionBox.get('loggedInUser');

  final prefs = Hive.box('prefs');
  final darkMode = prefs.get('darkMode', defaultValue: false);
  final fontSizePref = prefs.get('fontSize', defaultValue: 'normal');
  themeNotifier.value = darkMode ? ThemeMode.dark : ThemeMode.light;
  fontSizeNotifier.value = fontSizePref;

  runApp(MyApp(isRemembered: rememberedUser != null));
}

Future<Uint8List> _getEncryptionKey() async {
  const secureStorage = FlutterSecureStorage();
  String? keyString = await secureStorage.read(key: 'encryptionKey');

  if (keyString == null) {
    final key = Hive.generateSecureKey();
    keyString = key.join(',');
    await secureStorage.write(key: 'encryptionKey', value: keyString);
  }

  final keyList = keyString.split(',').map(int.parse).toList();
  return Uint8List.fromList(keyList);
}

double getFontSize(String size) {
  switch (size.toLowerCase()) {
    case 'small':
      return 14;
    case 'large':
      return 22;
    default:
      return 18;
  }
}

class MyApp extends StatelessWidget {
  final bool isRemembered;
  const MyApp({super.key, required this.isRemembered});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, _) {
        return ValueListenableBuilder<String>(
          valueListenable: fontSizeNotifier,
          builder: (context, fontSize, _) {
            final double dynamicFontSize = getFontSize(fontSize);
            return MaterialApp(
              title: 'MindShed',
              themeMode: currentTheme,
              theme: ThemeData(
                fontFamily: 'HappyMonkey',
                scaffoldBackgroundColor: const Color(0xFFE8E8E8),
                cardColor: Colors.white,
                dividerColor: Colors.black,
                colorScheme: const ColorScheme.light(surface: Colors.white),
                textTheme: TextTheme(
                  bodyMedium: TextStyle(fontSize: dynamicFontSize, color: Colors.black87),
                ),
                iconTheme: const IconThemeData(color: Colors.black),
              ),
              darkTheme: ThemeData(
                fontFamily: 'HappyMonkey',
                scaffoldBackgroundColor: const Color(0xFF1C1D22),
                cardColor: const Color(0xFF2A2B30),
                dividerColor: Colors.white54,
                colorScheme: const ColorScheme.dark(surface: Color(0xFF2A2B30)),
                textTheme: TextTheme(
                  bodyMedium: TextStyle(fontSize: dynamicFontSize, color: Colors.white),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              home: isRemembered ? const HomeScreen() : const LoginScreen(),
            );
          },
        );
      },
    );
  }
}