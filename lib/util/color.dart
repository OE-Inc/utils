
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:utils/util/utils.dart';

extension ColorExt on Color {

  bool get isLight {
    var relativeLuminance = computeLuminance();
    const double kThreshold = 0.15;
    const double fix = -0.1;
    return (relativeLuminance + fix) * (relativeLuminance + fix) > kThreshold;
  }

  Color get onColor => ColorExt.colorOfBrightness(!isLight);

  Color get onDividerColor => onColor.withOpacity(0.1);

  Color cardBlurColor(Color cardColor) {
    var hsv =  HSVColor.fromColor(this);

    return hsv.saturation < 0.1
        ? cardColor.withOpacity(0.4)
        : hsv.withSaturation(0.5).withValue(1.0).toColor()
    ;
  }

  static Color colorOfBrightness(bool isLight) => isLight ? Colors.white.withOpacity(0.85) : Colors.black87.withOpacity(0.618);

  Color addValue(double delta, { double? min, double? max, }) {
    var hsv = HSVColor.fromColor(this);
    return hsv.withValue((hsv.value + delta).toScope(min ?? 0, max ?? 1)).toColor();
  }

  Color addSaturation(double delta, { double? min, double? max, }) {
    var hsv = HSVColor.fromColor(this);
    return hsv.withSaturation((hsv.saturation + delta).toScope(min ?? 0, max ?? 1)).toColor();
  }

  Color toAccentColor() {
    return addSaturation(0.1).addValue(-0.1);
  }

  MaterialColor toMaterialColor() {
    var color = this;
    return MaterialColor(value, {
      50 : color.addValue(0.15).addSaturation(-0.25),
      100: color.addValue(0.12).addSaturation(-0.15),
      200: color.addValue(0.10).addSaturation(-0.10),
      300: color.addValue(0.05).addSaturation(-0.05),
      400: color,
      500: color.addValue(-0.05).addSaturation(0.05),
      600: color.addValue(-0.08).addSaturation(0.10),
      700: color.addValue(-0.12).addSaturation(0.15),
      800: color.addValue(-0.15).addSaturation(0.20),
      900: color.addValue(-0.18).addSaturation(0.25),
    });
  }

}

extension IntColorExt on int {

  Color get color => Color(this);

  bool get isLight => color.computeLuminance() > 0.5;
  bool get isDark => !isLight;

  Color get onColor => ColorExt.colorOfBrightness(!isLight);

}
