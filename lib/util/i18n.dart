

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:utils/util/app_env.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';

import 'log.dart';

const _TAG = "I18N";

class I18N {

  static void setLocalTimezone(String tz) async {
    _localTimezone = tz;
    Log.d(_TAG, () => "setLocalTimezone: $_localTimezone.");
    // Log.d(_TAG, () => "load native timezone: $_localTimezone, all timezones: ${timeZoneDatabase.locations}");

    setLocalLocation(tzLocation);
  }

  static Future<void> initTimezone() async {
    String nativeTz;
    try {
      nativeTz = await FlutterNativeTimezone.getLocalTimezone();
      Log.d(_TAG, () => "load native timezone: $nativeTz.");
    } catch (e) {
      nativeTz = local.name;
      Log.e(_TAG, () => "FlutterNativeTimezone.getLocalTimezone() fail, use default: $nativeTz, error: ", e);
    }
    // Log.d(_TAG, () => "load native timezone: $_localTimezone, all timezones: ${timeZoneDatabase.locations}");

    setLocalTimezone(nativeTz);
  }

  static Future<void> init() async {
    initializeTimeZones();
    await initTimezone();
    Log.d(_TAG, () => "load locale: $locale, timezone: $localTimezoneName/$localTimezone, timezoneOffset: $localTimezoneOffset MS.");
  }

  static Map<String, Location> get timezoneList => timeZoneDatabase.locations;

  /**
   * Find invalid i18n keys in .arb file with RegExp:
   *    "[a-zA-Z_]*[^a-zA-Z0-9_].*" *:
   */
  static String tzI18nStringKey(String name) => '_tz_${name.replaceAll('/', "__").replaceAll('-', '_')}';

  static String tzI18nName(String name) => localString(tzI18nStringKey(name));

  /// only for test.
  static bool? testUse24HourTimeFormat;

  static bool get use24HourTimeFormat {
    if (testUse24HourTimeFormat != null) return testUse24HourTimeFormat!;

    var ctx = AppEnv.context ?? AppEnv.rootContext;
    return ctx == null
        ? true
        : MediaQuery.of(ctx).alwaysUse24HourFormat
    ;
  }

  static bool isChinese() {
    return locale.languageCode.startsWith('zh');
  }

  static Locale get locale {
    Locale? l;
    try {
      if (AppEnv.context != null)
        l = Localizations.maybeLocaleOf(AppEnv.context!);
    } catch (e) {
      Log.w(_TAG, () => "get locale fail, use system locale, error:", e);
    }

    return l ?? systemLocale;
  }

  static int get localTimezoneOffset {
    return localTimezone.offset;
  }

  static TimeZone get localTimezone => tzLocation.currentTimeZone;
  static String get localTimezoneName => _localTimezone!;

  static int getTimezoneOffset(String? name, { int? utc, }) {
    return getTimezone(name, utc: utc).offset;
  }

  static TimeZone getTimezone(String? name, { int? utc, }) {
    return getTzLocation(name).timeZone(utc ?? DateTime.now().millisecondsSinceEpoch);
  }
  
  static Location getTzLocation(String? name) {
    if (name == null)
      return tzLocation;

    try {
      return getLocation(name);
    } catch (e) {
      Log.e(_TAG, () => "parse location/timezone error for $name: ", e);
    }

    return tzLocation;
  }

  static String? _invalidLastLoc;
  static Location get tzLocation {
    var tz = DateTime.now().timeZoneName;
    if (_invalidLastLoc != tz) {
      try {
        return getLocation(tz);
      } catch (e) {
        _invalidLastLoc = tz;
        Log.w(_TAG, () => "parse location/timezone error for default $tz: $e.");
      }
    }

    try {
      return getLocation(_localTimezone!);
    } catch (e) {
      Log.w(_TAG, () => "parse location/timezone error for native $_localTimezone: ", e);
    }

    return local;
  }

  static String? _localTimezone;
  static String? _systemLocaleStr;
  static Locale? _systemLocale;

  static Locale get systemLocale {
    // eg: 'en_US'
    String loc = 'en_US';

    try {
      loc = Platform.localeName;
    } catch (e) {
      Log.w(_TAG, () => "read Platform.localeName error, use default '$loc', error: $e.");
    }

    if (_systemLocaleStr == loc && _systemLocale != null)
      return _systemLocale!;

    var codes = loc.split(RegExp(r'[_-]'));

    Log.i(_TAG, () => "systemLocale: $loc, splits: $codes.");

    _systemLocaleStr = loc;
    return _systemLocale = Locale(codes.length == 0 ? "zh" : codes[0], codes.length > 1 ? codes[1] : "CN");
  }

  final List<Locale> systemLocales = WidgetsBinding.instance!.window.locales;

  /*
  // should put in mixin: WidgetsBindingObserver
  @override
  void didChangeLocales(List<Locale> locale) {
    // This is run when system locales are changed
    super.didChangeLocales(locale);
    setState(() {
      // Do actual stuff on the changes
    });
  }
   */

  static String localString(String str, { String? locale, String? prefix, }) {
    if (str == null)
      return str;

    var full = prefix != null ? "$prefix$str" : str;

    var result = Intl.message(
      full,
      name: full,
      desc: '',
      args: const [],
      locale: locale,
    );

    return prefix != null && result == full ? str : result;
  }
}

extension StringToI18nExt on String {

  String get toI18n => I18N.localString(this);

}