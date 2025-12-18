/// ============================================================
/// Device Info Helper Tests
/// ============================================================
///
/// Tests unitaires pour DeviceInfoHelper
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mukhliss/features/profile/data/services/device_info_helper.dart';

void main() {
  group('DeviceInfoHelper', () {
    group('getDeviceType', () {
      test('should return a valid device type string', () {
        // Act
        final deviceType = DeviceInfoHelper.getDeviceType();

        // Assert
        expect(
          deviceType,
          anyOf([
            'android',
            'ios',
            'web',
            'macos',
            'windows',
            'linux',
            'unknown',
          ]),
        );
      });
    });

    group('getPlatform', () {
      test('should return a capitalized platform name', () {
        // Act
        final platform = DeviceInfoHelper.getPlatform();

        // Assert
        expect(
          platform,
          anyOf([
            'Android',
            'iOS',
            'Web',
            'macOS',
            'Windows',
            'Linux',
            'Unknown',
          ]),
        );
      });
    });

    group('generateDeviceId', () {
      test('should generate a non-empty device ID', () async {
        // Act
        final deviceId = await DeviceInfoHelper.generateDeviceId();

        // Assert
        expect(deviceId, isNotEmpty);
      });

      test('should generate consistent device ID format', () async {
        // Act
        final deviceId = await DeviceInfoHelper.generateDeviceId();

        // Assert
        // Device ID should be a non-empty string
        expect(deviceId, isA<String>());
        expect(deviceId.length, greaterThan(0));
      });
    });

    group('getAppVersion', () {
      test('should return a version string', () async {
        // Act
        final version = await DeviceInfoHelper.getAppVersion();

        // Assert
        expect(version, isA<String>());
        // Version can be 'unknown' in test environment
        expect(version, isNotEmpty);
      });
    });

    group('getDeviceInfo', () {
      test('should return a map with device info', () async {
        // Act
        final info = await DeviceInfoHelper.getDeviceInfo();

        // Assert
        expect(info, isA<Map<String, dynamic>>());
        expect(info.containsKey('model'), isTrue);
        expect(info.containsKey('manufacturer'), isTrue);
      });
    });

    group('getDefaultDeviceName', () {
      test('should return a non-empty device name', () async {
        // Act
        final deviceName = await DeviceInfoHelper.getDefaultDeviceName();

        // Assert
        expect(deviceName, isNotEmpty);
        expect(deviceName, isA<String>());
      });
    });
  });
}
