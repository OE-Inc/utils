

const _TAG = "CollectionExt";

extension MapExt<K, V> on Map<K, V> {

  void removeNullValues() {
    removeWhere((k, v) => v == null);
  }

  void mapKeys(Map<K, K> keyMapping) {
    for (var k in keyMapping.keys) {
      var v = this[k];

      if (v != null) {
        this.remove(k);
        this[keyMapping[k]] = v;
      }
    }
  }

}


extension SetExt<K> on Set<K> {

}

extension ListExt<E> on List<E> {

  void removeNullValues() {
    removeWhere((e) => e == null);
  }

}