
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info/package_info.dart';
import 'package:utils/src/simple_interface.dart';

import 'log.dart';

const _TAG = "RunningEnv";

class RunningEnv {
  static var _f = false;
  static List<Callable1<bool, void>> stateWatchers = [];

  static bool get foreground { return _f; }

  static set foreground(bool f) {
    if (f == _f)
      return;

    _f = f;
    Log.i(_TAG, "foreground changed to: $f");

    stateWatchers.forEach((w) => w(f));
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

  static bool get isMobile => isAndroid || isIOS;

  static bool get isDesktop => !isWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  static String get platform => Platform.operatingSystem;

  static var _packageInfo;
  static PackageInfo get packageInfo {
    if (!isMobile)
      return null;

    if (_packageInfo != null)
      return _packageInfo;

    PackageInfo.fromPlatform()
      .then((p) => _packageInfo = p);

    return _packageInfo;
  }

  static init() async {
    if (isMobile && _packageInfo == null) {
      _packageInfo = await PackageInfo.fromPlatform();
    }
  }
}
