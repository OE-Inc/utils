
import 'dart:async';

import 'package:utils/src/running_env.dart';

import 'log.dart';

typedef OnChangeListener<T, OWNER> = void Function(OWNER owner, T newVal, T oldVal);

const String _TAG = "ValueObserver";

class ValueObserver<T, OWNER> {
  T         val;
  OWNER     owner;
  OnChangeListener<T, OWNER>        onChange;
  List<OnChangeListener<T, OWNER>>  listeners = [];

  ValueObserver(this.val, this.owner, OnChangeListener<T, OWNER> onChange) {
    this.onChange = onChange;
  }

  addListener(OnChangeListener<T, OWNER> listener) {
    this.listeners.add(listener);
    Timer.run(() => listener(owner, val, null));
  }

  removeListener(OnChangeListener<T, OWNER> listener) {
    this.listeners.remove(listener);
  }

  T value() { return val; }

  void set(T newVal) {
    T oldVal = val;

    if (newVal == val)
      return;

    this.val = newVal;

    OWNER o = this.owner;
    if (o != null && this.onChange != null)
      this.onChange(o, newVal, oldVal);

    try {
      for (var listener in listeners) {
        listener(o, newVal, oldVal);
      }
    } catch (e) {
      if (RunningEnv.isDebug)
        rethrow;

      Log.e(_TAG, "ValueObserver listener op error: $e");
    }
  }

  @override
  String toString() {
    return val != null ? val.toString() : "null";
  }
}
