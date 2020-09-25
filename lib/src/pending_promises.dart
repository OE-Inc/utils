
import 'dart:async';

import 'error.dart';

typedef ErrorHandler<KEY> = dynamic Function(KEY key);

class PendingPromises<KEY, VALUE> {

  // for common purpose.
  static PendingPromises pendingTasks = PendingPromises();
  static Map<String, bool> singleExecutingTasks = { };

  Map<KEY, List<Completer>>   pending = {};
  ErrorHandler<KEY>           error;

  List<KEY> keys() {
    return pending.keys.toList();
  }


  Future<T> singleExecute<T>(String key, int timeout, Future<T> getter()) async {
    var executing = singleExecutingTasks[key];

    if (executing == true) {
      return PendingPromises.pendingTasks.wait(key, timeout);
    }

    singleExecutingTasks[key] = true;
    try {
      var r = await getter();
      PendingPromises.pendingTasks.resolve(key, r);
      return r;
    } catch (e) {
      PendingPromises.pendingTasks.reject(key, e);
      rethrow;
    } finally {
      singleExecutingTasks.remove(key);
    }
  }

  void enterErrorState(ErrorHandler<KEY> error, bool applyToExisted) {
    if (error == null) {
      throw IllegalArgumentException("Should provide a error for ErrorState.");
    }

    this.error = error;

    if (applyToExisted) {
      apply(error);
    }
  }

  void enterNormalState() {
    this.error = null;
  }

  void apply(ErrorHandler<KEY> handler) {
    for (KEY key in keys()) {
      var err = handler(key);
      if (err != null) {
        reject(key, err);
      }
    }
  }

  Future<V> wait<V extends VALUE>(KEY key, int timeout, { String context, }) {
    ErrorHandler<KEY> handler = error;
    var err = handler != null ? handler(key) : null;
    if (err != null)
      return Future.error(err);

    List<Completer> list;

    Completer<V> f = Completer();

    list = pending[key];

    if (list == null) {
      list = [];
      pending[key] = list;
    }
    list.add(f);

    if (timeout > 0) {
      Timer(Duration(milliseconds: timeout), () {
        if (f.isCompleted)
          return;

        f.completeError(
            TimeoutException("wait timeout($timeout ms) for: $key, context: $context."));
        list.remove(f);
      });
    }

    return f.future;
  }

  void done<V>(KEY key, bool resolve, V valueOrExp, bool all) {
    List<Completer> list;
    Completer waiting;

    list = all ? pending.remove(key) : pending[key];

    if (list == null || list.length == 0)
      return;

    if (!all)
      waiting = list.removeAt(0);

    if (waiting != null && !waiting.isCompleted) {
      if (resolve)
        waiting.complete(valueOrExp);
      else
        waiting.completeError(valueOrExp);
    }

    if (all) {
      for (Completer<Object> next in list) {
        if (next.isCompleted)
          continue;

        if (resolve)
          next.complete(valueOrExp);
        else
          next.completeError(valueOrExp);
      }
    }
  }

  void resolve<V extends VALUE>(KEY key, V value, { bool all = true, }) {
    done(key, true, value, all);
  }

  void reject(KEY key, dynamic e, { bool all = true, }) {
    done(key, false, e, all);
  }

  void rejectAll(dynamic e) {
    Map<KEY, List<Completer>> all;

    if (pending.length == 0)
      return;

    all = pending;
    pending = {};

    for (KEY key in all.keys) {
      List<Completer> list = all[key];
      if (list == null || list.length == 0)
        continue;

      for (Completer next in list) {
        next.completeError(e);
      }
    }
  }

}
