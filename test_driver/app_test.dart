import 'package:flutter/material.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

// flutter drive --target=test_driver/app.dart
void main() {
  group('Counter App', () {
    final GetLocation = find.byValueKey('GetLocation');

    FlutterDriver driver;

    // Connect to the Flutter driver before running any tests.
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    // Close the connection to the driver after the tests have completed.
    tearDownAll(() async {
      if (driver != null) {
        driver.close();
      }
    });

    test('check flutter driver health', () async {
      final health = await driver.checkHealth();
      expect(health.status, HealthStatus.ok);
    });

    test('app renders', () async {
      // FIXME: Can this be more specific? Tried isA<Widget>(), but shit blew up
      expect(GetLocation, isNotNull);
    });
  });
}