
import 'dart:async';

import 'package:utils/src/utils.dart';

import 'simple_interface.dart';


class ValueCache<TYPE> {

  @protected
  TYPE                            value;
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
  
  TYPE get({ bool noGetter = false }) {
    int currMS = utc();
    if (    (value == null || currMS - interval >= lastUpdate)
        &&  (currMS - failInterval >= lastFailUpdate) ) {
      if (noGetter == true)
        return null;

      value = getter(value);
      if (value is Future)
        throw IllegalArgumentException('getter should always retures non Future<> value.');

      lastUpdate = currMS;
      lastFailUpdate = value == null ? currMS : 0;
    }

    return value;
  }
  
  TYPE set(TYPE newValue) {
    TYPE oldVal = value;
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

  TYPE getCached() {
    return super.get();
  }

  Future<TYPE> getAsync() async {
    int currMS = utc();
    if (    (value == null || currMS - interval >= lastUpdate)
        &&  (currMS - failInterval >= lastFailUpdate) ) {

      var val = getter(value);
      val = val is Future ? await val : val;

      value = val;
      lastUpdate = currMS;
      lastFailUpdate = value == null ? currMS : 0;
    }

    return value;
  }

}