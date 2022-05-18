
import 'dart:math' as Math;


abstract class ValueTransfer<FROM, TO> {

  TO transferTo(FROM val);
  FROM transferFrom(TO val);

  static PowValueTransfer     pow([double? pow]) => PowValueTransfer(pow: pow);
  static PowValueTransfer     gamma([double? pow]) => PowValueTransfer.gamma(pow: pow);
  static LinearValueTransfer  linear([double? scale]) => LinearValueTransfer(scale: scale);
  static ExpValueTransfer     exp() => ExpValueTransfer();

}

class LinearValueTransfer extends ValueTransfer<double, double> {
  late double scale;

  LinearValueTransfer({ double? scale, }) {
    this.scale = scale ?? 2.0;
  }

  @override
  double transferTo(double val) => val * scale;

  @override
  double transferFrom(double val) => val / scale;

}

class PowValueTransfer extends ValueTransfer<double, double> {
  late double pow;

  PowValueTransfer({ double? pow, }) {
    this.pow = pow ?? 4.0;
  }

  PowValueTransfer.gamma({ double? pow, }) {
    this.pow = pow ?? 2.2;
  }

  @override
  double transferTo(double val) => Math.pow(val == 0 ? double.minPositive : val, 1/pow).toDouble();

  @override
  double transferFrom(double val) => Math.pow(val, pow).toDouble();

}

class ExpValueTransfer extends ValueTransfer<double, double> {

  @override
  double transferTo(double val) => Math.log(val);

  @override
  double transferFrom(double val) => Math.exp(val);

}