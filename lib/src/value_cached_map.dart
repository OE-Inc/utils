
import 'dart:async';
import 'dart:collection';

import 'package:quiver/collection.dart';
import 'package:utils/src/utils.dart';

import 'pair.dart';
import 'simple_interface.dart';

class Key<KEY> extends Pair <KEY, int>{
  Key(KEY f, [ int s ]): super(f, s ?? utc());

  @override
  int get hashCode {
    return f.hashCode;
  }

  @override
  bool operator ==(other) => other is Key<KEY> && other.f == f;
}


class ValueCacheMap<KEY, VAL> {
  static const DEF_MAX_SIZE = 128;

  @protected
  Map<KEY, Pair<int, VAL>>      _values = HashMap();
  TreeSet<Key>                  latest = TreeSet(comparator: (l, r) => l.s - r.s);

  int                           maxSize = DEF_MAX_SIZE;
  int                           _interval = 0, failInterval = 0;

  KeyValueGetter<KEY, FutureOr<VAL>>    getter;
  Callable2<KEY, VAL, void>             onInvalidate;

  ValueCacheMap(this._interval, this.getter, { this.failInterval = 0, this.maxSize = DEF_MAX_SIZE, this.onInvalidate, }) {
    if (_interval <= 0 || maxSize <= 0 || getter == null)
      throw IllegalArgumentException("ValueCacheMap should init with a interval > 0, maxSize > 0, and getter not null: interval = $_interval, maxSize: $maxSize, getter: $getter");
  }
  
  void setFailInterval(int failInterval) {
    this.failInterval = failInterval;
  }
  
  void setInterval(int interval) {
    this._interval = interval;
  }

  Pair<int, VAL> setInside(KEY key, VAL val, int ms) {
    Pair<int, VAL> old = this._values[key] = Pair(ms, val);
    if (old != null)
      this.latest.remove(Key(key, old.f));
  
    this.latest.add(Key(key, ms));
  
    return old;
  }

  Pair<int, VAL> delInside(KEY key) {
    Pair<int, VAL> old = this._values.remove(key);
    if (old != null) {
      if (onInvalidate != null)
        onInvalidate(key, old.s);

      this.latest.remove(Key(key, old.f));
    }

    return old;
  }

  VAL get(KEY key, { bool noGetter = false }) {
    if (key == null)
      return null;
  
    Pair<int, VAL> p = _values[key];
    VAL val = p != null ? p.s : null;
  
    if (p != null) {
      int currMS = utc();
      if (currMS - p.f > (p.s == null ? failInterval : _interval)) {
        if (noGetter == true) {
          delInside(key);
          return null;
        }

        val = getter(key, p.s, p.f);
        if (val is Future)
          throw IllegalArgumentException("getter should never returns a Future<>.");

        setInside(key, val, currMS);
      }
    } else if (noGetter != true) {
      val = getter(key, null, 0);
      if (val is Future)
        throw IllegalArgumentException("getter should never returns a Future<>.");

      set(key, val);
    }
  
    return val;
  }

  bool setIfNotExist(KEY key, VAL newVal) {
    var old = get(key);
    if (old != null)
      return false;

    set(key, newVal);
    return true;
  }

  VAL set(KEY key, VAL newVal) {
    if (key == null)
      return null;
  
    Pair<int, VAL> old = setInside(key, newVal, utc());
  
    if (old == null && _values.length > maxSize) {
      Key del = latest.last;
      delInside(del.f);
    }
  
    return old != null ? old.s : null;
  }

  int succInterval(KEY key) {
    Pair<int, VAL> p = _values[key];
    return p != null && p.s != null ? utc() - p.f : -1;
  }
  
  int interval(KEY key) {
    Pair<int, VAL> p = _values[key];
    return p != null ? utc() - p.f : -1;
  }
  
  VAL invalidate(KEY key) {
    if (key == null)
      return null;
  
    Pair<int, VAL> old = delInside(key);
    return old != null ? old.s : null;
  }

  void invalidateWhere(bool Function(KEY key, VAL val) where) {
    for (var key in keys.toList()) {
      var val = _values[key];
      if (val == null)
        continue;

      if (!where(key, val.s)) {
        delInside(key);
      }
    }
  }

  bool containsKey(KEY key) { return _values.containsKey(key); }
  
  void clear() { _values.clear(); }

  int size() { return _values.length; }

  int get length { return _values.length; }

  Iterable<KEY> get keys { return _values.keys; }

  List<VAL> get values => _values.values.map((p) => p.s);
}


class ValueCacheMapAsync<KEY, VAL> extends ValueCacheMap<KEY, VAL> {
  ValueCacheMapAsync(int interval, KeyValueGetter<KEY, FutureOr<VAL>> getter, {
    int failInterval = 0, int maxSize = ValueCacheMap.DEF_MAX_SIZE, Callable2<KEY, VAL, void> onInvalidate,
    })
      : super(interval, getter, failInterval: failInterval, maxSize: maxSize, onInvalidate: onInvalidate);

  @Deprecated("use getAsync()/getCached(), Not usable for async cached.")
  @override
  VAL get(KEY key, { bool noGetter = false, }) {
    throw UnsupportedError('use getAsync(), Not usable for async cached.');
  }

  VAL getCached(KEY key) {
    return super.get(key, noGetter: true);
  }

  Future<T> getAsync<T extends VAL>(KEY key) async {
    if (key == null)
      return null;

    Pair<int, VAL> p = _values[key];
    VAL val = p != null ? p.s : null;

    if (p != null) {
      int currMS = utc();
      if (currMS - p.f > (p.s == null ? failInterval : _interval)) {
        var g = getter(key, p.s, p.f);
        val = g is Future ? await g : g;

        setInside(key, val, currMS);
      }
      // else print('key cached: $key');
    } else {
      var g = getter(key, null, 0);
      val = g is Future ? await g : g;

      set(key, val);
    }

    return val;
  }

}


class SqlValueCacheMapAsync<KEY, VAL> extends ValueCacheMapAsync<KEY, VAL> {
  SqlValueCacheMapAsync(int interval, getter) : super(interval, getter);
}