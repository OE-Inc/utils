
import 'package:better_log/betterlog.dart';
import 'package:utils/src/running_env.dart';

class Log {

  static const int
    VERBOSE = 2,
    DEBUG = 3,
    INFO = 4,
    WARN = 5,
    ERROR = 6,
    ASSERT = 7
  ;

  static const _levelStr = [ "VERBOSE", "DEBUG", "INFO", "WARN", "ERROR", "ASSERT" ];

  static log(String tag, String m, int level) {
    level = level ?? VERBOSE;
    if (level < VERBOSE) level = VERBOSE;
    else if (level > ASSERT) level = ASSERT;

    if (RunningEnv.isAndroid) {
      return BetterLog.log(tag, m, level);
    }

    var s = _levelStr[level - 2];
    print("[$s] $tag $m");
  }

  static a(String tag, String m) { return log(tag, m, ASSERT); }
  static d(String tag, String m) { return log(tag, m, DEBUG); }
  static v(String tag, String m) { return log(tag, m, VERBOSE); }
  static i(String tag, String m) { return log(tag, m, INFO); }
  static w(String tag, String m) { return log(tag, m, WARN); }
  static e(String tag, String m) { return log(tag, m, ERROR); }
}