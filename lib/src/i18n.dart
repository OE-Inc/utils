

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:utils/src/app_env.dart';
import 'package:intl/intl.dart';

import 'log.dart';

const _TAG = "I18N";

class I18N {
  static bool isChinese() {
    return locale.languageCode.startsWith('zh');
  }

  static Locale get locale {
    Locale l;
    try {
      if (AppEnv.context != null)
        l = Localizations.localeOf(AppEnv.context, nullOk: true);
    } catch (e) {
      Log.w(_TAG, "get locale fail, use system locale, error:", e);
    }

    return l ?? systemLocale;
  }


  static String _systemLocaleStr;
  static Locale _systemLocale;

  static Locale get systemLocale {
    // eg: 'en_US'
    var loc = Platform.localeName;
    if (_systemLocaleStr == loc && _systemLocale != null)
      return _systemLocale;

    var codes = loc.split(RegExp(r'[_-]'));

    Log.i(_TAG, "systemLocale: $loc, splits: $codes.");

    _systemLocaleStr = loc;
    return _systemLocale = Locale(codes.length == 0 ? "zh" : codes[0], codes.length > 1 ? codes[1] : "CN");
  }

  final List<Locale> systemLocales = WidgetsBinding.instance.window.locales;

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

  static String localString(String str, [ Locale locale ]) {
    return Intl.message(
      str,
      name: str,
      desc: '',
      args: [],
    );
  }
}