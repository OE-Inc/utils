
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import 'enum.dart';
import 'storage/annotation/sql.dart';

@deprecated
/// only used for auto import tip.
class JsonUtils { }

Object jsonEncodable(dynamic m) {
  // print("jsonEncodable: ${m.runtimeType}/$m.");
  if (m == null) return m;
  else if (m is Uint8List) return base64Encode(m);
  else if (m is Map || m is List) return m;
  else if (m is Enum) return m.value;
  else if ('${m.runtimeType}' == 'UniId') return m.toString();
  else if (m is SqlSerializable) return m.toJson();
  else if (m is Int64) return m.toString();

  try {
    return m.toJson();
  } catch (e) {
    return m;
  }
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
    // TODO: should recursive.
    var m = {};
    for (var k in this.keys) {
      var v = this[k];
      m[k] = jsonEncodable(v);
    }

    return jsonEncode(m, toEncodable: toJsonEncodable);
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
