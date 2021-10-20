import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DeviceMetrics {
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  late final String? os;
  late final String? oSVersion;

  late final String? locale;
  late final String? device;
  late final String? carrier;
  late final String? density;
  late final String? browser;
  late final String? resolution;
  late final String? appVersion;
  late final String? browserVersion;

  late final String? online;
  late final String? diskTotal;
  late final String? diskCurrent;

  late final String? cpu;
  late final String? ramTotal;
  late final String? ramCurrent;

  late final String? battery;
  late final String? orientation;

  late final String? root;
  late final String? muted;
  late final String? manufacture;

  DeviceMetrics._({
    this.os = null,
    this.oSVersion = null,
    this.device = null,
    this.resolution = null,
    this.carrier = null,
    this.appVersion = null,
    this.density = null,
    this.locale = null,
    this.browser = null,
    this.browserVersion = null,
    this.online = null,
    this.diskTotal = null,
    this.diskCurrent = null,
    this.cpu = null,
    this.ramTotal = null,
    this.ramCurrent = null,
    this.battery = null,
    this.orientation = null,
    this.root = null,
    this.muted = null,
    this.manufacture = null,
  });

  factory DeviceMetrics._android(AndroidDeviceInfo build) {
    return DeviceMetrics._(
      os: build.version.baseOS,
      manufacture: build.manufacturer,
    );
  }

  factory DeviceMetrics._ios(IosDeviceInfo build) {
    return DeviceMetrics._();
  }

  factory DeviceMetrics._linux(LinuxDeviceInfo data) {
    return DeviceMetrics._();
  }

  factory DeviceMetrics._browser(WebBrowserInfo data) {
    return DeviceMetrics._(
      os: data.platform,
      browserVersion: data.userAgent,
      locale: data.language,
      manufacture: data.vendor,
      appVersion: data.appVersion,
      ramCurrent: ' ${data.deviceMemory}',
      cpu: ' ${data.hardwareConcurrency}',
      browser: '${data.vendor} ${data.appVersion}',
    );
  }

  factory DeviceMetrics._macOs(MacOsDeviceInfo data) {
    return DeviceMetrics._();
  }

  factory DeviceMetrics._windows(WindowsDeviceInfo data) {
    return DeviceMetrics._();
  }

  static Future<DeviceMetrics> build() async {
    if (kIsWeb) {
      return DeviceMetrics._browser(await deviceInfoPlugin.webBrowserInfo);
    } else {
      if (Platform.isAndroid) {
        return DeviceMetrics._android(await deviceInfoPlugin.androidInfo);
      }

      if (Platform.isIOS) {
        return DeviceMetrics._ios(await deviceInfoPlugin.iosInfo);
      }

      if (Platform.isLinux) {
        return DeviceMetrics._linux(await deviceInfoPlugin.linuxInfo);
      }

      if (Platform.isMacOS) {
        return DeviceMetrics._macOs(await deviceInfoPlugin.macOsInfo);
      }

      if (Platform.isWindows) {
        return DeviceMetrics._windows(await deviceInfoPlugin.windowsInfo);
      }
    }
    return DeviceMetrics._();
  }

  Map<String, dynamic> metricsToJson() => <String, dynamic>{
        '_os': this.os,
        '_os_version': this.oSVersion,
        '_resolution': this.resolution,
        '_device': this.device,
        '_carrier': this.carrier,
        '_app_version': this.appVersion,
        '_density': this.density,
        '_browser': this.browser,
        '_browser_version': this.browserVersion,
        '_locale': this.locale,
      };

  @override
  String toString() {
    return 'DeviceMetrics{os: $os, oSVersion: $oSVersion, locale: $locale, device: $device, carrier: $carrier, density: $density, browser: $browser, resolution: $resolution, appVersion: $appVersion, browserVersion: $browserVersion, online: $online, diskTotal: $diskTotal, diskCurrent: $diskCurrent, cpu: $cpu, ramTotal: $ramTotal, ramCurrent: $ramCurrent, battery: $battery, orientation: $orientation, root: $root, muted: $muted, manufacture: $manufacture}';
  }
}
