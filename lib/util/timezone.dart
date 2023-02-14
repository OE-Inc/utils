

/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

import 'package:utils/util/i18n.dart';
import 'package:utils/util/log.dart';
import 'package:utils/util/unit.dart';
import 'package:utils/util/utils.dart';
import 'package:timezone/timezone.dart';


extension DateTimeUiExt on DateTime {

  String timeString({bool showSecond = false}) {
    var is24H = I18N.use24HourTimeFormat;
    String time = "${(is24H ? hour : hour12).toStringAligned(2)}:${minute.toStringAligned(2)}";

    if (showSecond) {
      return time + ":${second.toStringAligned(2)}";
    }

    if (!is24H) {
      time += " $amPm";
    }

    return time;
  }

  String dateString() {
    return "$year-${month.toStringAligned(2)}-${day.toStringAligned(2)}";
  }

  String toLocalIso8601String() {
    var offsHour = timeZoneOffset.inHours.abs().toStringAligned(2);
    var offsMin = (timeZoneOffset.inMinutes % 60).abs().toStringAligned(2);
    var offsSign = timeZoneOffset.isNegative ? "-" : "+";
    return "$year-${month.toStringAligned(2)}-${day.toStringAligned(2)}T${hour.toStringAligned(2)}:${minute.toStringAligned(2)}:${second.toStringAligned(2)}.${millisecond.toStringAligned(3)}$offsSign$offsHour$offsMin";
  }

}

extension TZDateTimeTimezoneExt on TZDateTime {

  TZDateTime toTimezone(String? timezone) {
    if (timeZoneName == timezone) return this;
    return TZDateTime.fromMillisecondsSinceEpoch(I18N.getTzLocation(timezone), millisecondsSinceEpoch);
  }

}

extension DateTimeTimezoneExt on DateTime {
  static const _TAG = "TimezoneUtils";
  static const MAX_DST_MS = TimeUnit.MS_PER_DAY * 2;

  static int adjustUtcWithDst(int time, int? dst, String? timezone) {
    if (dst == null || dst.abs() > MAX_DST_MS - 1) {
      return time;
    }

    var tz = I18N.getTimezone(timezone, utc: time);
    // Log.d(_TAG, () => 'tz.utcOffset: $timezone/$tz, dst: $dst.');

    return time - tz.offset + dst;
  }

  DateTime toTimezone(String? timezone) {
    if (timeZoneName == timezone) return this;
    return TZDateTime.fromMillisecondsSinceEpoch(I18N.getTzLocation(timezone), millisecondsSinceEpoch);
  }


}

