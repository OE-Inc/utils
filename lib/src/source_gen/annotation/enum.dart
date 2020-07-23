

export '../../enum.dart';

class EnumDefField {
  final String name;

  const EnumDefField(this.name);
}

/// Annotation class
/// Any Enum class should implement 'toSave()' and 'static fromSave()'.
class EnumDef {
  final String type;

  final List<String> prefix;
  final List<String> suffix;

  /// type is int or String.
  const EnumDef(this.type, {
    this.prefix,
    this.suffix,
  }) // : this.type = '$type'
  ;
}