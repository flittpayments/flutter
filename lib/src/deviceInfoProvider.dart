// device_info_provider.dart

import 'dart:convert';
import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

/// A utility class for gathering device information and generating device fingerprints
/// Similar to the Java DeviceInfoProvider but implemented with Flutter best practices
class DeviceInfoProvider {
  static const String _deviceIdKey = 'device_id';

  final BuildContext? context;
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final Uuid _uuid = const Uuid();

  /// Constructor - context is optional but recommended for screen size information
  DeviceInfoProvider({this.context});

  /// Creates a complete device fingerprint in the required format
  Future<Map<String, dynamic>> createDeviceFingerprint() async {
    final Map<String, dynamic> root = {};
    final Map<String, dynamic> data = {};

    // Generate a UUID for the device
    final deviceId = await getDeviceId();

    // Package info for version details
    final packageInfo = await PackageInfo.fromPlatform();

    // Fill device data
    data['user_agent'] = await getUserAgent();
    data['language'] = getDeviceLanguage();

    final screenSize = getScreenDimensions();
    data['resolution'] = [screenSize.width.round(), screenSize.height.round()];

    data['timezone_offset'] = getTimezoneOffset();
    data['sdk'] = "flutter-sdk";
    data['platform_name'] = kIsWeb ? 'web' : defaultTargetPlatform.toString().split('.').last.toLowerCase() + '_sdk';
    data['platform_version'] = packageInfo.version;

    if (defaultTargetPlatform == TargetPlatform.android) {
      data['platform_os'] = 'android';
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      data['platform_product'] = androidInfo.version.release;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      data['platform_os'] = 'ios';
      final iosInfo = await _deviceInfoPlugin.iosInfo;
      data['platform_product'] = iosInfo.systemVersion;
    } else {
      data['platform_os'] = defaultTargetPlatform.toString().split('.').last.toLowerCase();
      data['platform_product'] = 'unknown';
    }

    data['platform_type'] = await getDeviceType();

    // Set the root fields
    root['id'] = deviceId;
    root['data'] = data;

    return root;
  }

  /// Gets or generates a unique device identifier
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _uuid.v4().replaceAll('-', '');
      await prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  /// Gets the device's user agent string
  Future<String> getUserAgent() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return 'Mozilla/5.0 (Linux; Android ${androidInfo.version.release}; ${androidInfo.model}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.185 Mobile Safari/537.36';
      } catch (e) {
        return 'Android Device';
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        return 'Mozilla/5.0 (iPhone; CPU iPhone OS ${iosInfo.systemVersion.replaceAll('.', '_')} like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1';
      } catch (e) {
        return 'iOS Device';
      }
    } else {
      return 'Flutter Device';
    }
  }

  /// Gets the device's current language setting
  String getDeviceLanguage() {
    return PlatformDispatcher.instance.locale.toString();
  }

  /// Gets the screen dimensions
  Size getScreenDimensions() {
    if (context != null) {
      final mediaQuery = MediaQuery.of(context!);
      return mediaQuery.size;
    } else {
      // Use the window size if context is not available
      return window.physicalSize / window.devicePixelRatio;
    }
  }

  /// Gets the timezone offset in minutes
  int getTimezoneOffset() {
    final now = DateTime.now();
    final timeZoneOffset = now.timeZoneOffset;
    return -timeZoneOffset.inMinutes; // Negative to match the Java implementation
  }

  /// Determines if the device is a phone, tablet, or desktop
  Future<String> getDeviceType() async {
    // Get screen size to determine device type
    final Size screenSize = getScreenDimensions();
    final double shortestSide = screenSize.shortestSide;

    // Check if running on desktop
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'desktop';
    }

    // Determine if phone or tablet based on screen size
    if (shortestSide < 600) {
      return 'mobile';
    } else {
      return 'tablet';
    }
  }

  /// Returns the base64 encoded device fingerprint
  Future<String> getEncodedDeviceFingerprint() async {
    try {
      final fingerprint = await createDeviceFingerprint();
      return base64Encode(utf8.encode(jsonEncode(fingerprint)));
    } catch (e) {
      // Fallback to a minimal fingerprint if there's an error
      try {
        final minimal = {
          'id': _uuid.v4().replaceAll('-', ''),
          'data': {}
        };
        return base64Encode(utf8.encode(jsonEncode(minimal)));
      } catch (ex) {
        return "";
      }
    }
  }
}
