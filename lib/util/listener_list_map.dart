

/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

import 'dart:async';

import 'package:utils/util/simple_interface.dart';

import 'log.dart';

class ListenerListMap<KEY, LISTENER> {

  Map<KEY, List<LISTENER>>  listeners = {};

  List<LISTENER>? operator [](KEY key) => listeners[key];

  Iterable<KEY> get keys => listeners.keys;

  void listen(KEY key, LISTENER listener) {
    var list = listeners[key];

    if (list == null) {
      list = listeners[key] = [listener];
    } else
      list.add(listener);
  }

  void eachDo(KEY key, Callable1<LISTENER, FutureOr<void>> run) async {
    var list = listeners[key];
    if (list == null)
      return;

    for (var l in list) {
      try {
        var r = run(l);
        if (r is Future)
          await r;
      } catch(e) {
        Log.e("$runtimeType", () => "eachDo for listener error: ", e);
      }
    }
  }

  bool remove(KEY key, LISTENER listener) {
    var list = listeners[key];
    bool removed = list?.remove(key) ?? false;

    if (removed && list?.isEmpty == true)
      listeners.remove(key);

    return removed;
  }

  List<LISTENER>? removeAll(KEY key) {
    return listeners.remove(key);
  }

  bool containsKey(KEY key) {
    return listeners.containsKey(key);
  }

  bool contains(KEY key, LISTENER listener) {
    return listeners[key]?.contains(listener) ?? false;
  }

  int get length => listeners.length;
  bool get isEmpty => listeners.isEmpty;
  bool get isNotEmpty => listeners.isNotEmpty;

  int lengthOf(KEY key) => listeners[key]?.length ?? 0;

}