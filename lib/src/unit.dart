
import 'dart:math';

class TimeUnit {
  static const
    MS_PER_MINUTE = 60 * 1000,
    MS_PER_HOUR = 60 * MS_PER_MINUTE,
    MS_PER_DAY = 24 * MS_PER_HOUR,
    MS_PER_YEAR = 365 * MS_PER_DAY
      ;



  static String utcString(int ms) {
    return "$ms/${DateTime.fromMillisecondsSinceEpoch(ms).toIso8601String()}";
  }


  static String _fixedWidth(int num, [int width = 2]) {
    var s = "$num";
    var delta = width - s.length;
    if (delta <= 0) return s;
    else {
      var l = "000000000000000".substring(0, delta);
      return l + s;
    }
  }

  static String lowSecondString(int ms) {
    return (ms / 1000.0).toStringAsFixed(ms > 6000 ? 0 : 1);
  }

  static String periodString(int ms) {
    if (ms == null) return null;

    String p = ms < 0 ? '-' : '';
    ms = ms.abs();
    if (ms < 1000) {
      return "$p${_fixedWidth(ms, 3)} MS";
    }

    if (ms < 60 * 1000) {
      return "$p${ms ~/ 1000}.${_fixedWidth(ms % 1000, 3)} S";
    }

    var str = "${_fixedWidth((ms ~/ TimeUnit.MS_PER_MINUTE) % 60)}:${_fixedWidth((ms % MS_PER_MINUTE) ~/ MS_PER_MINUTE)}";

    if (ms >= TimeUnit.MS_PER_HOUR) {
      str = "${_fixedWidth((ms ~/ TimeUnit.MS_PER_HOUR) % 24)}:$str";
    }

    if (ms >= TimeUnit.MS_PER_DAY) {
      str = "${(ms ~/ MS_PER_DAY) % 365}D/$str";
    }

    if (ms >= TimeUnit.MS_PER_YEAR) {
      str = "${ms ~/ MS_PER_YEAR}Y/$str";
    }

    return "$p$str";
  }

}
