
class TimeUnit {
  static const
    MS_PER_MINUTE = 60 * 1000,
    MS_PER_HOUR = 60 * MS_PER_MINUTE,
    MS_PER_DAY = 24 * MS_PER_HOUR,
    MS_PER_YEAR = 365 * MS_PER_DAY
      ;



  static String readable(int ms) {
    if (ms == null) return null;

    String p = ms < 0 ? '-' : '';
    ms = ms.abs();
    if (ms < 1000) {
      return "$p$ms MS";
    }

    if (ms < 60 * 1000) {
      return "$p${ms ~/ 1000}.${ms % 1000} S";
    }

    var str = "${(ms ~/ TimeUnit.MS_PER_MINUTE) % 60}:${(ms % MS_PER_MINUTE) ~/ MS_PER_MINUTE} S";

    if (ms > TimeUnit.MS_PER_HOUR) {
      str = "${(ms ~/ TimeUnit.MS_PER_HOUR) % 24}:$str";
    }

    if (ms > TimeUnit.MS_PER_DAY) {
      str = "${(ms ~/ MS_PER_DAY) % 365}D/$str";
    }

    if (ms > TimeUnit.MS_PER_YEAR) {
      str = "${ms ~/ MS_PER_YEAR}Y/$str";
    }

    return "$p$str";
  }

}
