

import 'dart:async';

import 'log.dart';

const _TAG = "MultiCompleter";

class MultiCompleter<T> {

  dynamic error;
  T result;

  bool _isCompleted = false;
  List<Completer<T>> _pending = [];

  void complete(T result, dynamic error) {
    if (_isCompleted) {
      Log.e(_TAG, "Should never complete twice: ", error);
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
    Completer c = Completer<T>();

    if (_isCompleted) {
      error == null
          ? c.complete(result)
          : c.completeError(error);
    } else
      _pending.add(c);

    return c.future;
  }
}