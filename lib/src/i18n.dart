

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:utils/src/app_env.dart';

class I18N {
  static bool isChinese() {
    return locale.languageCode.startsWith('zh');
  }

  static Locale get locale => AppEnv.context != null ? Localizations.localeOf(AppEnv.context, nullOk: true) ?? systemLocale : systemLocale;

  static Locale get systemLocale {
    // eg: 'en_US'
    var loc = Platform.localeName;
    var codes = loc.split(RegExp(r'[_-]'));
    return Locale(codes[0], codes[1]);
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
    if (AppEnv.context == null)
      return str;

    // TODO: should use i18n.
    return str;
  }
}