import 'package:health/health.dart';

// Test to understand the health package API
class HealthPackageTest {
  static void runTest() {
    print('🧪 Testing Health Package API...\n');

    // List all available health data types
    print('Available Health Data Types:');
    for (var type in HealthDataType.values) {
      print('  ${type.toString()}');
    }

    print('\nAvailable Health Units:');
    for (var unit in HealthDataUnit.values) {
      print('  ${unit.toString()}');
    }

    print('\nAvailable Workout Types:');
    // WorkoutHealthType.values.forEach((type) {
    //   print('  ${type.toString()}');
    // });

    print('\n✅ Health package API test completed!');
  }
}

void main() {
  HealthPackageTest.runTest();
}
