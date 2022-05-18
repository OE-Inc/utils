
import 'package:utils/util/i18n.dart';
import 'package:utils/util/utils.dart';

extension TimeUnitOnIntExt on int {
  String get periodString => TimeUnit.periodString(this)!;
  String get periodUiString => TimeUnit.periodUiString(this)!;
  String get utcString => TimeUnit.utcString(this)!;
  String get utcDateString => TimeUnit.utcDateString(this)!;
  String get utcPeriodString => TimeUnit.utcPeriodString(this)!;
}

class TimeUnit {

  static const
    // MAX = 0x7FFFFFFFFFFFFFFF,
    // NOTE: Javascript only support max 2^53.
    MAX = 0x1FFFFFFFFFFFFF,
    MS_PER_MINUTE = 60 * 1000,
    MS_PER_HOUR = 60 * MS_PER_MINUTE,
    MS_PER_DAY = 24 * MS_PER_HOUR,
    MS_PER_YEAR = 365 * MS_PER_DAY
      ;

  static bool isMax(int ms) => ms >= MAX/2;

  static String? utcPeriodString(int? ms) {
    if (ms == null)
      return null;

    if (ms == 0)
      return "0";

    if (isMax(ms))
      return "+INF";

    return "${utcString(ms)}[delta: ${periodString(DateTime.now().millisecondsSinceEpoch - ms)}]";
  }


  static String? utcDateString(int? ms) {
    if (ms == null)
      return null;

    if (ms == 0)
      return "0";

    if (isMax(ms))
      return "+INF";

    return "${DateTime.fromMillisecondsSinceEpoch(ms).toIso8601String().substring(0, 10)}";
  }

  static String? utcString(int? ms) {
    if (ms == null)
      return null;

    if (ms == 0)
      return "0";

    if (isMax(ms))
      return "+INF";

    return "${DateTime.fromMillisecondsSinceEpoch(ms)}";
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

  @Deprecated("should use .periodUiString()")
  static String lowSecondString(int ms) {
    return (ms / 1000.0).toStringAsFixed(ms > 6000 ? 0 : 1);
  }

  static String? periodUiString(int? ms) {
    if (ms == null) return null;

    if (ms < MS_PER_MINUTE*3)
      return "${(ms / 1000).autoRoundString()} ${I18N.localString("second")}";
    else if (ms < MS_PER_HOUR*2)
      return "${(ms / MS_PER_MINUTE).autoRoundString()} ${I18N.localString("minute")}";
    else if (ms < MS_PER_DAY*3)
      return "${(ms / MS_PER_HOUR).autoRoundString()} ${I18N.localString("hour")}";
    else
      return "${(ms / MS_PER_DAY).autoRoundString()} ${I18N.localString("day")}";
  }

  static String? periodString(int? ms) {
    if (ms == null) return null;

    if (isMax(ms))
      return "+INF";

    String p = ms < 0 ? '-' : '';
    ms = ms.abs();
    if (ms < 1000) {
      return "$p${_fixedWidth(ms, 3)} MS";
    } else if (ms < 60 * 1000) {
      return "$p${ms ~/ 1000}.${_fixedWidth(ms % 1000, 3)} S";
    }

    var str = "${_fixedWidth((ms ~/ TimeUnit.MS_PER_MINUTE) % 60)}:${_fixedWidth((ms % MS_PER_MINUTE) ~/ 1000)}";

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
