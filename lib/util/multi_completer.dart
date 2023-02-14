

/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

import 'dart:async';

import 'log.dart';
import 'utils.dart';

const _TAG = "MultiCompleter";

extension CompleterExt<T> on Completer<T> {

  setTimeout(int timeout, String? tip) {
    delay(timeout).then((value) {
      if (isCompleted)
        return;

      completeError(TimeoutError(tip ?? "completer timeout.", timeout));
    });
  }

}

class MultiCompleter<T> {

  /// wait any result, and others ignored.
  /// different to Future.any(): will throw the error and return the first result.
  static Future<dynamic> waitAny(Iterable<Future> futures) {
    var c = Completer();

    for (var f in futures) {
      f.then((value) {
        if (c.isCompleted) return;
        c.complete(value);
      }).catchError((e) {
        if (c.isCompleted) return;
        c.completeError(e);
      });
    }

    return c.future;
  }

  dynamic error;
  T? result;

  bool _isCompleted = false;
  List<Completer<T>> _pending = [];

  bool get isCompleted => _isCompleted;

  void complete(T result, dynamic error) {
    if (_isCompleted) {
      Log.e(_TAG, () => "Should never complete twice: ", error);
      return;
    }

    _isCompleted = true;

    this.error = error;
    this.result = result;

    var ps = _pending;
    _pending = [];
    
    for (var c in ps) {
      error == null
          ? c.complete(result)
          : c.completeError(error);
    }
  }

  Future<T> wait() {
    var c = Completer<T>();

    if (_isCompleted) {
      error == null
          ? c.complete(result)
          : c.completeError(error);
    } else
      _pending.add(c);

    return c.future;
  }
}