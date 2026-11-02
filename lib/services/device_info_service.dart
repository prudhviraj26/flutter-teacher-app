import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceTelemetry {
  final String deviceUuid;
  final String deviceModel;
  final String deviceManufacturer;
  final String osVersion;
  final String platform;
  final String appVersion;
  final String locale;
  final String timezone;

  DeviceTelemetry({
    required this.deviceUuid,
    required this.deviceModel,
    required this.deviceManufacturer,
    required this.osVersion,
    required this.platform,
    required this.appVersion,
    required this.locale,
    required this.timezone,
  });

  Map<String, dynamic> toJson() => {
        'deviceUuid': deviceUuid,
        'deviceModel': deviceModel,
        'deviceManufacturer': deviceManufacturer,
        'osVersion': osVersion,
        'platform': platform,
        'appVersion': appVersion,
        'locale': locale,
        'timezone': timezone,
      };
}

class DeviceInfoService {
  static DeviceTelemetry? _cachedTelemetry;

  static Future<DeviceTelemetry> getDeviceTelemetry() async {
    if (_cachedTelemetry != null) return _cachedTelemetry!;

    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    String deviceUuid = '';
    String deviceModel = 'Unknown';
    String deviceManufacturer = 'Unknown';
    String osVersion = 'Unknown';
    String platformName = 'unknown';

    try {
      if (kIsWeb) {
        platformName = 'web';
        final webInfo = await deviceInfo.webBrowserInfo;
        deviceModel = webInfo.browserName.name;
        deviceManufacturer = webInfo.vendor ?? 'Browser';
        osVersion = webInfo.userAgent ?? 'Web';
      } else if (Platform.isAndroid) {
        platformName = 'android';
        final androidInfo = await deviceInfo.androidInfo;
        deviceUuid = androidInfo.id;
        deviceModel = androidInfo.model;
        deviceManufacturer = androidInfo.manufacturer;
        osVersion =
            'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        platformName = 'ios';
        final iosInfo = await deviceInfo.iosInfo;
        deviceUuid = iosInfo.identifierForVendor ?? '';
        deviceModel = iosInfo.utsname.machine;
        deviceManufacturer = 'Apple';
        osVersion = 'iOS ${iosInfo.systemVersion}';
      }
    } catch (e) {
      debugPrint('[DeviceInfoService] Error querying platform info: $e');
    }

    // Fallback persistent UUID if hardware ID is unavailable
    if (deviceUuid.trim().isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      var storedUuid = prefs.getString('veyho_device_uuid');
      if (storedUuid == null || storedUuid.isEmpty) {
        storedUuid =
            'dev-${DateTime.now().millisecondsSinceEpoch}-${(1000 + (DateTime.now().microsecond % 9000))}';
        await prefs.setString('veyho_device_uuid', storedUuid);
      }
      deviceUuid = storedUuid;
    }

    final locale = PlatformDispatcher.instance.locale.toString();
    final timezone = DateTime.now().timeZoneName;
    final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

    _cachedTelemetry = DeviceTelemetry(
      deviceUuid: deviceUuid,
      deviceModel: deviceModel,
      deviceManufacturer: deviceManufacturer,
      osVersion: osVersion,
      platform: platformName,
      appVersion: appVersion,
      locale: locale,
      timezone: timezone,
    );

    return _cachedTelemetry!;
  }
}

