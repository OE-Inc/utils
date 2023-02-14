
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:utils/core/error.dart';
import 'package:utils/util/i18n.dart';
import 'package:utils/util/simple_interface.dart';

export './web_stub/running_env.dart'
  if (dart.library.js) './running_env_web.dart'
;


import 'connectivity.dart';
import 'log.dart';

const _TAG = "RunningEnv";

class RunningEnv {
  static var _f = false;
  static final List<Callable1<bool, void>> stateWatchers = [];
  static final List<Runnable> onShutdown = [];

  // app is updating versions. only set true when new app updates runs first time. Should set before any checkUpdating() called.
  static bool? versionUpdating;
  static Map<String, bool> _updatingMap = { };

  static int startUtc = DateTime.now().millisecondsSinceEpoch;

  static bool checkUpdating(String key) {
    if (versionUpdating != true) {
      if (versionUpdating == null)
        Log.e(_TAG, () => "Should init versionUpdating before any checkUpdating() called.", Error().thrown());

      return false;
    }

    var u = _updatingMap[key];
    if (u != null)
      return false;

    _updatingMap[key] = true;
    return true;
  }

  static bool get foreground { return _f; }

  static set foreground(bool f) {
    if (f == _f)
      return;

    _f = f;
    Log.i(_TAG, () => "foreground changed to: $f");

    stateWatchers.forEach((w) => w(f));
  }

  static close() {
    for (var s in onShutdown) {
      s();
    }
  }

  static bool get shouldScan { return foreground; }
  static bool get shouldSelectBearer { return foreground; }


  static bool get isRelease => !isDebug;
  static bool get isDebug {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }

  static bool get isWeb => kIsWeb;

  static bool get isAndroid => !isWeb && Platform.isAndroid;
  static bool get isIOS => !isWeb && Platform.isIOS;
  static bool get isWindows => !isWeb && Platform.isWindows;
  static bool get isLinux => !isWeb && Platform.isLinux;
  static bool get isMacOS => !isWeb && Platform.isMacOS;

  static bool get isMobile => isAndroid || isIOS;

  static bool get isDesktop => !isWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  static String get platform => isWeb ? 'web' : Platform.operatingSystem;

  static Map<String, String> get queryParameter {
    return Uri.base.queryParameters;
  }

  static int? get androidSdkInt => cachedDeviceInfo.android?.version.sdkInt;

  static final cachedDeviceInfo = DeviceInfo();

  static DeviceInfoPlugin? _deviceInfo;
  static DeviceInfoPlugin get deviceInfo {
    return _deviceInfo ??= DeviceInfoPlugin();
  }

  static Future<String> getDeviceDisplayString() async {
    if (isWeb) {
      var wi = await deviceInfo.webBrowserInfo;
      // eg: 'Chrome(Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.55 Safari/537.36, MacIntel)'
      return '${wi.browserName}(${wi.userAgent}, ${wi.platform})';

    } if (isAndroid) {
      var ai = await deviceInfo.androidInfo;
      // eg: 'MI 8(mi8, xiaomi)'
      return '${ai.hardware}(${ai.model}, ${ai.brand})';

    } else if (isIOS) {
      var ii = await deviceInfo.iosInfo;
      // eg: 'My iPhone(iPhone)'
      return '${ii.name}(${ii.model})';

    } else if (isWindows) {
      var wi = await deviceInfo.windowsInfo;
      // eg: 'My Computer(4 cores)'
      return '${wi.computerName}(${wi.numberOfCores} cores)';

    } else if (isLinux) {
      var li = await deviceInfo.linuxInfo;
      // eg: 'Fedora 17 (Beefy Miracle)'
      return li.prettyName;
    } else {
      return '<Unknown>';
    }
  }


  static PackageInfo? _packageInfo;
  static PackageInfo? get packageInfo {
    if (_packageInfo != null)
      return _packageInfo;

    _loadPackageInfo();

    return _packageInfo;
  }

  static Future<DeviceInfo> loadDeviceInfo() async {
    cachedDeviceInfo.android = isAndroid ? await deviceInfo.androidInfo : null;
    cachedDeviceInfo.ios = isIOS ? await deviceInfo.iosInfo : null;
    cachedDeviceInfo.macos = isMacOS ? await deviceInfo.macOsInfo : null;
    cachedDeviceInfo.linux = isLinux ? await deviceInfo.linuxInfo : null;
    cachedDeviceInfo.windows = isWindows ? await deviceInfo.windowsInfo : null;
    cachedDeviceInfo.web = isWeb ? await deviceInfo.webBrowserInfo : null;

    return cachedDeviceInfo;
  }

  static Future<void> _loadPackageInfo() async {
    try {
      var p = await PackageInfo.fromPlatform();
      if (p.packageName == '')
        p = PackageInfo(appName: p.appName, packageName: '', version: p.version, buildNumber: p.buildNumber, buildSignature: p.buildSignature);

      _packageInfo = p;
      Log.d(_TAG, () => "load packageInfo: { appName: ${p.appName}, packageName: ${p.packageName}, version: ${p.version}, buildNumber: ${p.buildNumber} }");
    } catch (e) {
      _packageInfo = PackageInfo(appName: '[UNKNOWN-APP-NAME]', packageName: '', version: '[UNKNOWN-VERSION]', buildNumber: '[UNKNOWN-BUILD-NUMBER]');

      Log.e(_TAG, () => "load packageInfo error: $e, use unknown: ${_packageInfo}.");
    }
  }

  static init() async {
    _loadPackageInfo();
    loadDeviceInfo();

    await I18N.init();
    // init connectivity here.
    connectivityDetector;
  }

}


class DeviceInfo {
  AndroidDeviceInfo? android;
  IosDeviceInfo? ios;
  LinuxDeviceInfo? linux;
  MacOsDeviceInfo? macos;
  WindowsDeviceInfo? windows;
  WebBrowserInfo? web;
}

class AndroidSdkInt {
  static const
    Android_4_4 = 19,
    Android_4_4W = 20,
    Android_5_0 = 21,
    Android_5_1 = 22,
    Android_6_0 = 23,

    Android_7_0 = 24,
    Android_7_1 = 25,

    Android_8_0 = 26,
    Android_8_1 = 27,

    Android_9_0 = 28,
    Android_10_0 = 29,

    Android_11_0 = 30,
    Android_12_0 = 31,
    Android_12_L = 32,
    Android_13_0 = 33,

    _x_ = -1
  ;
}