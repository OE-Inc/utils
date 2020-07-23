

import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:utils/src/unit.dart';

import 'log.dart';
import 'qpt.dart';
import 'utils.dart';

const String _TAG = 'PriorityPendingList';

abstract class PriorityPendingItem {
  int get     priority => 0;
  int         createUtc = utc();
  int         timeout;

  List<Completer<bool>> waiting = [];

  Future<void> start();

  void onComplete(bool success) {
    waiting.forEach((w) => w.complete(success));
    waiting.clear();
  }

  Future<bool> waitComplete() {
    var c = Completer<bool>();
    waiting.add(c);
    return c.future;
  }

  bool expired() {
    return utc() - createUtc >= timeout;
  }

  int get duration => utc() - createUtc;

  String moreString();

  @override
  String toString() {
    return '$runtimeType { priority: $priority, expired: ${expired()}, duration: ${TimeUnit.readable(duration)}, ${moreString()}, timeout: $timeout, }';
  }
}

class PriorityPendingList<ITEM extends PriorityPendingItem> {
  @protected
  SplayTreeMap<int, List<ITEM>>   pending = SplayTreeMap();
  @protected
  List<ITEM>                      processing = [];
  @protected
  int                             maxSize = 20;

  bool                            enableQpt = true;
  Qpt                             qpt = Qpt(10 * 1000);

  int _size;
  int get size => _size ?? (_size = pending.isEmpty ? 0 : pending.values.fold(0, ((val, item) => val + item.length)));

  @protected
  List<ITEM> getList(int priority) {
    return pending[priority] ?? (pending[priority] = []);
  }

  bool remove(ITEM item) {
    _size = null;
    return pending[item.priority]?.remove(item);
  }

  Future<T> push<T extends ITEM>(ITEM item) async {
    var l = getList(item.priority);
    _size = null;
    l.add(item);
    if (enableQpt) qpt.add();

    Log.d(_TAG, "push item: $item.");

    if (size == 1 && processing.isEmpty)
      next();

    checkMaxSize();

    await item.waitComplete();
    return item;
  }

  void checkMaxSize() {
    if (size <= maxSize)
      return;

    var removed = [];

    int removedSize = 5;
    var keys = pending.keys.toList().reversed;

    for (var priority in keys) {
      if (removedSize <= 0)
        break;

      var l = pending[priority];
      if (l.length == 0)
        continue;

      var sz = min(l.length, removedSize);
      removedSize -= sz;

      removed.addAll(l.sublist(0, sz));
      l.removeRange(0, sz);
    }

    Log.w(_TAG, 'removing low priority list: $removed.');
  }

  ITEM getNext({ bool remove = false }) {
    List<int> removed;
    ITEM t;

    for (var priority in pending.keys) {
      var l = pending[priority];

      if (l.isEmpty) {
        if (remove == true) {
          removed = removed ?? [];
          removed.add(priority);
        }
        continue;
      }

      t = l.removeAt(0);
      break;
    }

    if (removed != null) {
      for (var p in removed)
        pending.remove(p);

      _size = null;
    }

    if (t != null)
      _size = null;

    return t;
  }

  @protected
  onDone(ITEM item, bool success) {
    Log.d(_TAG, "item result, success: $success, item: $item");
    item.onComplete(success);
    processing.remove(item);
    next();
  }

  @protected
  next() {
    if (size == 0)
      return;

    var item = getNext();
    Log.d(_TAG, "start item: $item");

    // already timeout...
    if (item.expired()) {
      return next();
    }

    processing.add(item);

    item.start()
        .then((_) => onDone(item, true))
        .catchError((e, s) {
          Log.e(_TAG, "process item error: $e, $s");
          onDone(item, false);
        });
    ;
  }

}