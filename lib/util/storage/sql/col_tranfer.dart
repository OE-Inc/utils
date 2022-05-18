


import 'dart:convert';
import 'dart:typed_data';

import 'package:utils/util/storage/annotation/sql.dart';

import '../../json.dart';

class JsonItemTransfer<ITEM_TYPE, ITEM_SAVE_TYPE> extends SqlSerializer<List<ITEM_TYPE>, String> {

  final SqlSerializer<ITEM_TYPE, ITEM_SAVE_TYPE>?     itemCoder;

  JsonItemTransfer(this.itemCoder): super(

    fromSave: (String key, dynamic col, { bool fromJson = true, }) {
      if (col == null || col.length < 3)
        return [];

      var from = jsonDecode(col) as List;
      return itemCoder != null
          ? from.map((v) => itemCoder.fromSave(key, v, fromJson: fromJson)).toList()
          : from as List<ITEM_TYPE>;
    },

    toSave: (String key, List<ITEM_TYPE> col, { bool? toJson }) {
      var save = itemCoder != null && itemCoder.toSave != null
          ? col.map((v) => itemCoder.toSave!(key, v, toJson: toJson))
          : col;

      return jsonEncode(save, toEncodable: toJsonEncodable);
    }

  );

}

class Base64Transfer extends SqlSerializer<Uint8List, String> {
  Base64Transfer(): super(
    fromSave: (String key, dynamic col, { bool? fromJson, }) {
      return base64Decode(col);
    },
    toSave: (String key, Uint8List col, { bool? toJson }) {
      return base64Encode(col);
    }
  );
}

class JsonTransfer<JSON_TYPE> extends SqlSerializer<JSON_TYPE, String> {
  dynamic clazz;

  /// clazz should be a JsonSerializable class, not instance.
  JsonTransfer(this.clazz): super(
    fromSave: (String key, dynamic col, { bool? fromJson, }) {
      var map = jsonDecode(col);
      return clazz.fromJson(map);
    },

    toSave:(String key, JSON_TYPE col, { bool? toJson }) {
      return jsonEncode(col);
    }
  );
}