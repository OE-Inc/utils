
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

import 'dart:typed_data';

import 'package:ansicolor/ansicolor.dart';
import 'package:better_log/better_log.dart';
import 'package:utils/core/error.dart';
import 'package:utils/util/running_env.dart';

_utc() { return DateTime.now().toIso8601String(); }

abstract class Logger {
  void write(String line);
}

/**
 * Replace old to new.
 *
 * replace  : (Log\.\w\([^,]+\,) *([^( ])
 * to       : $1 () => $2
 *
 */
class Log {

  static bool enable = !RunningEnv.isRelease;
  static Logger? logger;

  static const int
    VERBOSE = 2,
    DEBUG = 3,
    INFO = 4,
    WARN = 5,
    ERROR = 6,
    ASSERT = 7
  ;

  static const _levelStr = [ "VERBOSE", "DEBUG", "INFO", "WARN", "ERROR", "ASSERT" ];

  static final List<AnsiPen> _colors = [
    new AnsiPen()..white(),
    new AnsiPen()..blue(),
    new AnsiPen()..green(),
    new AnsiPen()..yellow(),
    new AnsiPen()..red(),
    new AnsiPen()..red(bg: true),
  ];

  static log(String tag, String m, int? level) {
    String? line;
    level = level ?? VERBOSE;
    if (level < VERBOSE) level = VERBOSE;
    else if (level > ASSERT) level = ASSERT;

    var l = logger;
    if (l != null) {
      line ??= "[${_utc()}] [${_levelStr[level - 2]}] $tag $m";

      l.write('\n');
      l.write(line);
    }

    if (RunningEnv.isAndroid) {
      return BetterLog.log(tag, m, level);
    }

    line ??= "[${_utc()}] [${_levelStr[level - 2]}] $tag $m";
    print(_colors[level - 2](line));
  }

  static a(String tag, String Function() m, [dynamic e, dynamic stacktrace]) { if (enable) log(tag, e != null ? '${m()} ${errorMsg(e, stacktrace)}' : m(), ASSERT); }
  static d(String tag, String Function() m, [dynamic e, dynamic stacktrace]) { if (enable) log(tag, e != null ? '${m()} ${errorMsg(e, stacktrace)}' : m(), DEBUG); }
  static v(String tag, String Function() m, [dynamic e, dynamic stacktrace]) { if (enable) log(tag, e != null ? '${m()} ${errorMsg(e, stacktrace)}' : m(), VERBOSE); }
  static i(String tag, String Function() m, [dynamic e, dynamic stacktrace]) { if (enable) log(tag, e != null ? '${m()} ${errorMsg(e, stacktrace)}' : m(), INFO); }
  static w(String tag, String Function() m, [dynamic e, dynamic stacktrace]) { if (enable) log(tag, e != null ? '${m()} ${errorMsg(e, stacktrace)}' : m(), WARN); }
  static e(String tag, String Function() m, [dynamic e, dynamic stacktrace]) { if (enable) log(tag, e != null ? '${m()} ${errorMsg(e, stacktrace)}' : m(), ERROR); }

  static ad(String tag, String m, [dynamic e, dynamic stacktrace]) { if (enable) log(tag, e != null ? '$m ${errorMsg(e, stacktrace)}' : m, ASSERT); }
  static dd(String tag, String m, [dynamic e, dynamic stacktrace]) { if (enable) log(tag, e != null ? '$m ${errorMsg(e, stacktrace)}' : m, DEBUG); }
  static vd(String tag, String m, [dynamic e, dynamic stacktrace]) { if (enable) log(tag, e != null ? '$m ${errorMsg(e, stacktrace)}' : m, VERBOSE); }
  static id(String tag, String m, [dynamic e, dynamic stacktrace]) { if (enable) log(tag, e != null ? '$m ${errorMsg(e, stacktrace)}' : m, INFO); }
  static wd(String tag, String m, [dynamic e, dynamic stacktrace]) { if (enable) log(tag, e != null ? '$m ${errorMsg(e, stacktrace)}' : m, WARN); }
  static ed(String tag, String m, [dynamic e, dynamic stacktrace]) { if (enable) log(tag, e != null ? '$m ${errorMsg(e, stacktrace)}' : m, ERROR); }
}