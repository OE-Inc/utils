

/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

const _TAG = "CollectionExt";

extension MapExt<K, V> on Map<K, V> {

  void removeNullValues({ bool recursive = false, }) {
    removeWhere((k, v) => v == null);
    if (recursive == true) {
      this.forEach((key, value) {
        if (value is List) value.removeNullValues();
        else if (value is Map) value.removeNullValues();
      });
    }
  }

  void mapKeys(Map<K, K> keyMapping) {
    for (var k in keyMapping.keys) {
      var v = this[k];

      if (v != null) {
        this.remove(k);
        this[keyMapping[k]!] = v;
      }
    }
  }

  void removeAll(Map<K, V> excluded) {
    if (excluded.length < length) {
      excluded.forEach((key, value) { remove(key); });
    } else
      removeWhere((key, value) => excluded.containsKey(key));
  }

  Map<K, V> excluded(Map<K, V> excluded) {
    return { ...this }..removeAll(excluded);
  }

  Map<K, V> clone() {
    return { ...this, };
  }

}


extension SetExt<K> on Set<K> {

}

extension ListExt<E> on List<E> {

  void removeNullValues({ bool recursive = false, }) {
    removeWhere((e) => e == null);

    if (recursive == true) {
      this.forEach((value) {
        if (value is List) value.removeNullValues();
        else if (value is Map) value.removeNullValues();
      });
    }
  }

}