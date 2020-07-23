
import 'dart:convert';

@deprecated
/// only used for auto import tip.
class JsonUtils { }

extension MapJsonExt on Map {

  toJson() {
    return jsonEncode(this);
  }

}

extension ListJsonExt on List {

  toJson() {
    return jsonEncode(this);
  }

}