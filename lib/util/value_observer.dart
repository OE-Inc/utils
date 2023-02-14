
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:utils/util/running_env.dart';

import 'log.dart';

typedef OnChangeListener<T, OWNER> = void Function(OWNER owner, T newVal, T oldVal);

const String _TAG = "ValueObserver";

class ValueObserver<T, OWNER> {
  @protected
  T         val;
  @protected
  OWNER     owner;
  OnChangeListener<T, OWNER>?       onChange;
  List<OnChangeListener<T, OWNER>>  listeners = [];

  ValueObserver(this.val, this.owner, this.onChange);

  addListener(OnChangeListener<T, OWNER> listener) {
    listeners.remove(listener);
    listeners.add(listener);
    Timer.run(() => listener(owner, val, val));
  }

  removeListener(OnChangeListener<T, OWNER> listener) {
    listeners.remove(listener);
  }

  T value() { return val; }

  void set(T newVal) {
    T oldVal = val;

    if (newVal == val)
      return;

    this.val = newVal;

    OWNER o = this.owner;
    if (o != null && this.onChange != null)
      this.onChange!(o, newVal, oldVal);

    try {
      for (var listener in listeners) {
        listener(o, newVal, oldVal);
      }
    } catch (e) {
      if (RunningEnv.isDebug)
        rethrow;

      Log.e(_TAG, () => "ValueObserver listener op error: ", e);
    }
  }

  @override
  String toString() {
    return "$val";
  }
}
