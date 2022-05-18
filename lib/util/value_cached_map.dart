
import 'dart:async';
import 'dart:math';

import 'package:quiver/collection.dart';
import 'package:utils/util/unit.dart';
import 'package:utils/util/utils.dart';

import 'lock.dart';
import 'log.dart';
import 'pair.dart';
import 'simple_interface.dart';

class Key<KEY> extends Pair <KEY, int> implements Comparable {
  Key(KEY f, int s): super(f, s);

  @override
  int get hashCode {
    return f.hashCode;
  }

  @override
  bool operator ==(other) => identical(this, other)
      || (other is Key<KEY> && other.f == f);

  /// 注意：compareTo 必须要对不同的 key，产生完全相同的总顺序，即全体 key 排序具有传递性。
  /// 而不是 A < B, B < C, 但是 A > C。
  /// 之前 s 相同，或者 s 相同时，使用另一个局部有序的结果，则总体不再有序，会导致 remove/contains 结果异常。
  @override
  int compareTo(other) {
    var r = other as Key<KEY>;
    if (s == r.s) {
      assert(f == r.f);
    }

    return s - r.s;
  }
}


class ValueCacheMap<KEY, VAL> {
  static const _TAG = "ValueCacheMap";
  static const DEF_MAX_SIZE = 382;
  static int _instanceId = 0;

  final                         _values = <KEY, Pair<int, VAL>> { };
  final                         _latest = TreeSet<Key<KEY>>();
  int                           _lastUtc = 0;

  int                           maxSize = DEF_MAX_SIZE;
  int                           shrinkSize;
  int                           _interval = 0, failInterval = 0;
  bool                          feedWhenGet;
  final int                     instanceId = ++_instanceId;


  KeyValueGetter<KEY, FutureOr<VAL>>    getter;
  Callable2<KEY, VAL, void>?            onInvalidate;

  ValueCacheMap(this._interval, this.getter,
      {
    this.failInterval = 0,
    this.maxSize = DEF_MAX_SIZE,
    this.shrinkSize = DEF_MAX_SIZE - 32,
    this.onInvalidate,
    this.feedWhenGet = false,
  }) {
    if (_interval <= 0 || maxSize <= 0 || getter == null)
      throw IllegalArgumentException("ValueCacheMap should init with a interval > 0, maxSize > 0, and getter not null: interval = $_interval, maxSize: $maxSize, getter: $getter");

    shrinkSize = max(max(1, shrinkSize), (maxSize + shrinkSize) ~/ 2);
  }

  int uniqueUtc() {
    var u = utc();
    if (u <= _lastUtc) {
      u = _lastUtc + 1;
    }

    return _lastUtc = u;
  }

  void setFailInterval(int failInterval) {
    this.failInterval = failInterval;
  }
  
  void setInterval(int interval) {
    _interval = interval;
  }

  /// returns old value.
  Pair<int, VAL>? setInside(KEY key, VAL val, int ms) {
    Pair<int, VAL>? old = _values[key];
    if (old != null && !_latest.remove(Key(key, old.f))) {
      Log.e(_TAG, () => "[$instanceId] set/remove latest error, _values: ${_values.length}, _latest: ${_latest.length}, key: [${key.runtimeType}]$key.");
    }

    _values[key] = Pair(ms, val);
    _latest.add(Key(key, ms));

    return old;
  }

  Pair<int, VAL>? delInside(KEY key) {
    Pair<int, VAL>? old = _values.remove(key);
    try {
      if (old != null && !_latest.remove(Key(key, old.f))) {
        Log.e(_TAG, () => "[$instanceId] remove latest error, _values: ${_values.length}, _latest: ${_latest.length}, key: [${key.runtimeType}]$key.");
      }
    } catch (e) {
      Log.e(_TAG, () => "[$instanceId] remove latest occurs error: $e, key: [${key.runtimeType}]$key, clear all latest cache.");
      _latest.clear();
    }

    if (old != null) {
      if (onInvalidate != null && old.s != null)
        onInvalidate!(key, old.s);
    }

    return old;
  }

  VAL get(KEY key) {
    return getAllowNoGetter(key, noGetter: false) as VAL;
  }

  VAL? getAllowNoGetter(KEY key, { bool noGetter = false }) {
    if (key == null)
      return null;

    Pair<int, VAL>? p = _values[key];

    VAL? val;
    if (p != null) {
      val = p.s;

      int currMS = uniqueUtc();
      if (currMS - p.f > (p.s == null ? failInterval : _interval)) {
        if (noGetter == true) {
          delInside(key);
          return null;
        }

        var nv = getter(key, p.s, p.f);
        if (nv is Future)
          throw IllegalArgumentException("getter should never returns a Future<>.");

        setInside(key, val = nv, currMS);
      }

      if (feedWhenGet == true) {
        setInside(key, p.s, currMS);
        p.f = currMS;
      }
    } else if (noGetter != true) {
      var nv = getter(key, null, 0);
      if (nv is Future)
        throw IllegalArgumentException("getter should never returns a Future<>.");

      set(key, val = nv);
    }
  
    return val;
  }

  /// return true if not exist old value, and set new value.
  bool setIfNotExist(KEY key, VAL newVal) {
    var old = get(key);
    if (old != null)
      return false;

    set(key, newVal);
    return true;
  }

  VAL? set(KEY key, VAL newVal) {
    if (key == null)
      return null;

    if (_values.length > maxSize) {
      while (_values.length > shrinkSize) {
        KEY delKey = _latest.isNotEmpty ? _latest.first.f : _values.keys.first;
        // Log.d(_TAG, () => "[$instanceId] remove latest, values: ${_values.length}, limit: [$shrinkSize, $maxSize], latest: ${_latest.length}, del: [${delKey.runtimeType}] $delKey.");
        delInside(delKey);
      }
    }

    Pair<int, VAL>? old = setInside(key, newVal, uniqueUtc());

    return old?.s;
  }

  int succInterval(KEY key) {
    Pair<int, VAL>? p = _values[key];
    return p?.s != null ? utc() - p!.f : -1;
  }
  
  int interval(KEY key) {
    Pair<int, VAL>? p = _values[key];
    return p != null ? utc() - p.f : -1;
  }
  
  VAL? invalidate(KEY? key) {
    if (key == null)
      return null;
  
    Pair<int, VAL>? old = delInside(key);
    return old?.s;
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
  
  void clear() {
    _values.clear();
    _latest.clear();
  }

  int size() { return _values.length; }

  int get length { return _values.length; }

  Iterable<KEY> get keys { return _values.keys; }

  Iterable<VAL> get values => _values.values.map((p) => p.s);
}


class ValueCacheMapAsync<KEY, VAL> extends ValueCacheMap<KEY, VAL> {
  ValueCacheMap<KEY, Lock>?  locks;

  bool get withLock => locks != null;

  ValueCacheMapAsync(int interval, KeyValueGetter<KEY, FutureOr<VAL>> getter, {
    int failInterval = 0, int maxSize = ValueCacheMap.DEF_MAX_SIZE, Callable2<KEY, VAL, void>? onInvalidate,
    bool lock = false,
    })
      : super(interval, getter, failInterval: failInterval, maxSize: maxSize, onInvalidate: onInvalidate) {
    if (lock)
      locks = ValueCacheMap(3 * TimeUnit.MS_PER_MINUTE, (key, oldVal, lastUpd) => oldVal ?? Lock(), feedWhenGet: true);
  }

  @Deprecated("use getAsync()/getCached(), not usable for async cached.")
  @override
  VAL get(KEY key) {
    throw UnsupportedError('use getAsync(), not usable for async cached.');
  }

  @Deprecated("use getAsync()/getCached(), not usable for async cached.")
  @override
  VAL? getAllowNoGetter(KEY key, { bool noGetter = false, }) {
    throw UnsupportedError('use getAsync(), not usable for async cached.');
  }

  VAL? getCached(KEY key) {
    return super.getAllowNoGetter(key, noGetter: true);
  }

  Future<T> getAsync<T extends VAL>(KEY key) async {
    return locks != null
        ? locks!.get(key).guard(() => _getAsync(key))
        : _getAsync(key);
  }

  Future<T> _getAsync<T extends VAL>(KEY key) async {
    Pair<int, VAL>? p = _values[key];
    VAL val;

    if (p != null) {
      val = p.s;

      int currMS = uniqueUtc();
      if (currMS - p.f > (p.s == null ? failInterval : _interval)) {
        var g = getter(key, p.s, p.f);
        val = g is Future ? await g : g;

        setInside(key, val, currMS);
      }
      // else print('key cached: $key');
    } else {
      var g = getter(key, null, 0);
      val = g is Future ? await g : g;

      super.set(key, val);
    }

    return val as T;
  }

  Lock? getLock(KEY key) => locks?.get(key);

  Future<VAL?> setLocked(KEY key, VAL newVal) {
    if (locks == null)
      throw UnsupportedError('use set(), not usable for async(no lock) cached.');

    return locks!.get(key).guard(() => super.set(key, newVal));
  }

  @override
  VAL? set(KEY key, VAL newVal) {
    if (locks != null)
      throw UnsupportedError('use setLocked(), not usable for async+lock cached.');

    return super.set(key, newVal);
  }

}


class SqlValueCacheMapAsync<KEY, VAL> extends ValueCacheMapAsync<KEY, VAL> {
  SqlValueCacheMapAsync(int interval, getter) : super(interval, getter);
}