
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

import 'dart:async';

import 'package:utils/util/error.dart';
import 'package:utils/util/simple_interface.dart';

import 'log.dart';

class Lock {
  static const _TAG = "Lock";

  bool _locked = false;
  List<Completer> _pending = [];

  bool get locked => _locked;

  bool tryLock() {
    if (_locked)
      return false;

    _locked = true;
    return true;
  }

  Future<T> guard<T>(Callable<FutureOr<T>> run) async {
    try {
      if (!tryLock()) {
        await lock();
      }

      var r = run();
      return r is Future ? await r : r;
    } finally {
      unlock();
    }
  }

  Future<void> lock() async {
    if (_locked) {
      var c = Completer();
      _pending.add(c);
      return c.future;
    }

    _locked = true;
  }

  void unlock() {
    if (!_locked) {
      Log.e(_TAG, () => "", RuntimeException("Should not unlock a not-locking: $this.").thrown());
      return;
    }

    if (_pending.isEmpty) {
      _locked = false;
      return;
    }

    var next = _pending.removeAt(0);
    Future.microtask(() => next.complete(null));
  }

}