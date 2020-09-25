
import 'dart:convert';
import 'dart:typed_data';

import 'enum.dart';
import 'storage/annotation/sql.dart';

@deprecated
/// only used for auto import tip.
class JsonUtils { }

Object jsonEncodable(Object m) {
  // print("jsonEncodable: $m.");
  if (m is Uint8List) return base64Encode(m);
  else if (m is Map || m is List) return m;
  else if (m is Enum) return m.value;
  else if ('${m.runtimeType}' == 'UniId') return m.toString();
  else if (m is SqlSerializable) return m.toJson();
  else return m;
}

var toJsonEncodable = (m) => jsonEncodable(m);

abstract class SqlSerializableJsonStringType<CLASS> extends SqlSerializable<String, CLASS> {
  /// called before saving to database, transfer memory object to db type.
  String toSave() {
    return jsonEncode(toJson(), toEncodable: toJsonEncodable);
  }

  dynamic toJson();

  /// called after loading from database, and transfer to a memory object.
  /// NOTE: could returns a new instance if old instance is const.
  CLASS fromSave(String col) {
    return fromJson(jsonDecode(col));
  }

  CLASS fromJson(dynamic col);

  const SqlSerializableJsonStringType();
}

extension MapJsonExt on Map {

  String toJson() {
    return jsonEncode(this, toEncodable: toJsonEncodable);
  }

}

extension ListJsonExt on List {

  String toJson() {
    return jsonEncode(this, toEncodable: toJsonEncodable);
  }

}

abstract class Jsonable<T> {

  Map<String, dynamic>  toJson();

  T  fromJson(Map<String, dynamic> map);

}

class JsonableClass <T> extends Jsonable<T> {

  @override
  T fromJson(Map<String, dynamic> map) {
    // TODO: implement fromJson
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

}
