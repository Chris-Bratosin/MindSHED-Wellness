import 'apple_health_integration.dart';
import '../data_source_manager.dart';

// Test Apple Health integration
class AppleHealthTest {
  static Future<void> runTest() async {
    print('🍎 Testing Apple Health Integration...\n');

    // Test 1: Check availability
    await _testAvailability();

    // Test 2: Check permissions
    await _testPermissions();

    // Test 3: Test data fetching (if permissions granted)
    await _testDataFetching();

    print('\n✅ Apple Health tests completed!');
  }

  static Future<void> _testAvailability() async {
    print('📱 Testing HealthKit Availability...');

    try {
      bool available = await AppleHealthIntegration.isAvailable();
      print('   HealthKit Available: $available');

      if (available) {
        print('   ✅ HealthKit is available on this device');
      } else {
        print('   ❌ HealthKit is not available on this device');
      }
    } catch (e) {
      print('   ❌ Error checking availability: $e');
    }

    print('');
  }

  static Future<void> _testPermissions() async {
    print('🔐 Testing HealthKit Permissions...');

    try {
      Map<dynamic, bool> permissions =
          await AppleHealthIntegration.checkPermissions();

      if (permissions.isEmpty) {
        print('   No permissions data available');
      } else {
        print('   Current permissions:');
        permissions.forEach((type, granted) {
          print('     ${type.toString()}: ${granted ? "✅" : "❌"}');
        });
      }

      // Test requesting permissions
      print('   Requesting permissions...');
      bool granted = await AppleHealthIntegration.requestPermissions();
      print('   Permissions granted: ${granted ? "✅" : "❌"}');
    } catch (e) {
      print('   ❌ Error checking permissions: $e');
    }

    print('');
  }

  static Future<void> _testDataFetching() async {
    print('📊 Testing Data Fetching...');

    try {
      // Create a date range for today
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end =
          start.add(Duration(days: 1)).subtract(Duration(milliseconds: 1));

      print('   Fetching data for today...');
      var data = await AppleHealthIntegration.fetchHealthData(
          DateTimeRange(start: start, end: end));

      print('   ✅ Data fetched successfully!');
      print('   Steps: ${data.steps}');
      print('   Heart Rate: ${data.heartRate ?? "N/A"} bpm');
      print('   HRV: ${data.hrv ?? "N/A"} ms');
      print('   Active Minutes: ${data.activeMinutes}');
      print('   Exercise Sessions: ${data.exerciseSessions}');
      print('   Data Source: ${data.source}');
      print('   Data Quality: ${data.quality}');

      if (data.sleep != null) {
        print(
            '   Sleep Duration: ${data.sleep!.totalSleep.inHours}h ${data.sleep!.totalSleep.inMinutes % 60}m');
        print(
            '   Sleep Efficiency: ${(data.sleep!.sleepEfficiency * 100).toStringAsFixed(1)}%');
        print(
            '   Deep Sleep: ${data.sleep!.deepSleepPercentage?.toStringAsFixed(1) ?? "N/A"}%');
        print(
            '   REM Sleep: ${data.sleep!.remSleepPercentage?.toStringAsFixed(1) ?? "N/A"}%');
      } else {
        print('   Sleep Data: Not available');
      }
    } catch (e) {
      print('   ❌ Error fetching data: $e');
    }

    print('');
  }
}

// Run the test when this file is imported
void main() async {
  await AppleHealthTest.runTest();
}
