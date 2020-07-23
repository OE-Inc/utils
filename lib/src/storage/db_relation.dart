

import 'package:utils/src/unit.dart';
import 'package:utils/src/value_cached_map.dart';

class Rel_1_1<KEY, VALUE> {

  ValueCacheMap<KEY, VALUE>   cacheMap = ValueCacheMap(30 * TimeUnit.MS_PER_MINUTE, (key, oldVal, lastUpd) {
    // TODO: memory database.
    return oldVal;
  });

  clearCache() {
    // cacheMap.clear();
  }

  VALUE get(KEY key, { VALUE where, bool distinct = false, String field, VALUE fallback, }) {
    return cacheMap.get(key) ?? fallback;
  }

  VALUE set(KEY key, VALUE value, { VALUE where, }) {
    var old = cacheMap.get(key);
    cacheMap.set(key, value);
    return old;
  }

  VALUE remove(KEY key) {
    var old = cacheMap.get(key);
    cacheMap.invalidate(key);
    return old;
  }

  bool containsKey(KEY key) {
    return cacheMap.get(key) != null;
  }

  bool contains(VALUE value) {
    throw UnimplementedError();
  }

  int size() {
    return cacheMap.size();
  }

  void removeAll() {
    clear();
  }

  List<VALUE> values() {
    return cacheMap.values;
  }

  List<KEY> keys() {
    return cacheMap.keys;
  }

  first() {
    throw UnimplementedError();
  }

  filter() {
    throw UnimplementedError();
  }

  apply() {
    throw UnimplementedError();
  }

  clear() {
    clearCache();
  }

}