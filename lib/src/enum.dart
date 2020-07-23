
import 'storage/annotation/sql.dart';

abstract class Enum<CLASS, ENUM_TYPE__> extends SqlSerializable<ENUM_TYPE__, CLASS> {
  final ENUM_TYPE__   value;
  /// eg: '==', serialized.
  final String        name;
  /// eg: 'equal', not serialized.
  final String        field;

  const Enum(this.value, this.name, { this.field });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Enum<CLASS, ENUM_TYPE__> &&
              runtimeType == other.runtimeType &&
              value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    if (value == null) return 'null';
    return field != null ? "$name[$value/$field]" : "$name[$value]";
  }


  @override
  ENUM_TYPE__ toSave() => value;
}

abstract class EnumNum<CLASS, T extends num> extends Enum<CLASS, T> {
  const EnumNum(T value, String name, { String field }) : super(value, name, field: field);


  bool operator > (/*EnumNum<CLASS, T>*/ dynamic o) => value >  (o is T ? o : o.value);
  bool operator >=(/*EnumNum<CLASS, T>*/ dynamic o) => value >= (o is T ? o : o.value);
  bool operator < (/*EnumNum<CLASS, T>*/ dynamic o) => value <  (o is T ? o : o.value);
  bool operator <=(/*EnumNum<CLASS, T>*/ dynamic o) => value <= (o is T ? o : o.value);
}

abstract class EnumInt<CLASS> extends EnumNum<CLASS, int> {
  const EnumInt(int value, String name, { String field }) : super(value, name, field: field);

  @override
  String toString() {
    if (value == null) return super.toString();
    return field != null ? "$name[0x${value.toRadixString(16)}/$field]" : "$name[0x${value.toRadixString(16)}]";
  }

}