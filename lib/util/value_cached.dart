
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

import 'dart:async';

import 'package:utils/util/utils.dart';

import 'simple_interface.dart';


class ValueCache<TYPE> {

  @protected
  TYPE?                           value;
  @protected
  ValueGetter<FutureOr<TYPE>>     getter;
  @protected
  int                   lastUpdate = 0, interval = 0, lastFailUpdate = 0, failInterval = 0;
  // private AtomicBoolean           lock = new AtomicBoolean(false);
  
  ValueCache(this.value, this.interval, this.getter, { this.failInterval = 0 }) {
    if (getter == null)
      throw new IllegalArgumentException("Cannot init ValueCache with null ValueGetter.");
  
    if (interval < 0 || failInterval < 0)
      throw new IllegalArgumentException("Cannot init ValueCache with negative interval: $interval, or fail-interval: $failInterval");
  }
  
  void setFailInterval(int failInterval) {
    this.failInterval = failInterval;
  }
  
  void setInterval(int interval) {
    this.interval = interval;
  }
  
  TYPE get() {
    return getAllowNoGetter(noGetter: false)!;
  }

  TYPE? getAllowNoGetter({ bool noGetter = false }) {
    int currMS = utc();
    if (    (value == null || currMS - interval >= lastUpdate)
        &&  (currMS - failInterval >= lastFailUpdate) ) {
      if (noGetter == true)
        return null;

      var nv = getter(value);
      if (nv is Future)
        throw IllegalArgumentException('getter should always retures non Future<> value.');

      value = nv;
      lastUpdate = currMS;
      lastFailUpdate = value == null ? currMS : 0;
    }

    return value;
  }
  
  TYPE? set(TYPE newValue) {
    TYPE? oldVal = value;
    value = newValue;
    lastUpdate = utc();
    lastFailUpdate = 0;
    return oldVal;
  }
  
  void invalidate() {
    value = null;
    lastUpdate = lastFailUpdate = 0;
  }
}

class ValueCacheAsync<TYPE> extends ValueCache<TYPE> {
  ValueCacheAsync(TYPE value, int interval, getter, { int failInterval = 0 }) : super(value, interval, getter, failInterval: failInterval);

  @Deprecated('use getAsync()/getCached() for async version.')
  @override
  TYPE get({ bool noGetter = false }) {
    throw UnsupportedError('use getAsync() for async version.');
  }

  TYPE? getCached() {
    return super.getAllowNoGetter(noGetter: true);
  }

  Future<TYPE> getAsync() async {
    int currMS = utc();
    if (    (value == null || currMS - interval >= lastUpdate)
        &&  (currMS - failInterval >= lastFailUpdate) ) {

      var val = getter(value);

      value = val is Future ? await val : val;
      lastUpdate = currMS;
      lastFailUpdate = value == null ? currMS : 0;
    }

    return value as TYPE;
  }

}