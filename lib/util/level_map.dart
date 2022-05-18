

class Level2Map<K1, K2, V> {

  Map<K1, Map<K2, V>> map = { };

  bool get isNotEmpty => map.isNotEmpty;
  bool get isEmpty => map.isEmpty;

  Iterable<K1> get keys => map.keys;

  Map<K2, V>? operator [](K1 key) => map[key];

  void add(K1 k, K2 item, V val) {
    var m = map[k];
    if (m == null)
      m = map[k] = { };

    m[item] = val;
  }

  V? get(K1 k, K2 item) {
    var m = map[k];
    if (m == null)
      return null;
    return m[item];
  }

  V? remove(K1 k, K2 item) {
    var m = map[k];
    if (m == null)
      return null;

    var v = m.remove(item);
    if (m.isEmpty)
      map.remove(m);

    return v;
  }

}
