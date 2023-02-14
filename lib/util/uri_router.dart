


/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

import 'package:flutter/foundation.dart';

import 'error.dart';
import 'log.dart';
import 'pair.dart';

typedef RouterProc = bool Function(Map<String, dynamic> data);


const _TAG = "UriRouter";

class UriRouter {

  @protected List<Pair<Object, RouterProc>> routers = [];

  void addRouterString(String path, RouterProc cb) {
    if (path == null || cb == null)
      throw new IllegalArgumentException("Please AddRouter with valid string-path: $path, callback: $cb!");

    routers.add(Pair(path, cb));
    //if (previous != null)
    //    Log.w(_TAG, () => "CAUTION: you have redefine a router for path: " + path);
  }

  void addRouterRegExpString(String path, RouterProc cb) {
    if (path == null || cb == null)
      throw new IllegalArgumentException("Please AddRouter with valid RegExp-path: $path, callback: $cb!");

    routers.add(Pair(RegExp(path), cb));
  }

  void addRouterRegExp(RegExp path, RouterProc cb) {
    if (path == null || cb == null)
      throw new IllegalArgumentException("Please AddRouter with valid RegExp-path: $path, callback: $cb!");

    routers.add(Pair(path, cb));
  }

  /// path: String or RegExp.
  void removeRouter(Object path) {
    for (int idx = 0; idx < routers.length; ++idx) {
      Pair<Object, RouterProc> p = routers[idx];
      if (p.f == path) {
        routers.remove(idx--); // check again from current position.
        Log.v(_TAG, () => "Successfully removed a router for: $path");
      }
    }
  }

  bool routeData(Map<String, dynamic> data) {
    String? uri = data["uri"];
    if (uri == null) {
      Log.v(_TAG, () => "Passed route data: $data");
      return false;
    }

    if (uri == null) {
      Log.v(_TAG, () => "Passed route data: $data");
      return false;
    }

    // check string path:
    for (int idx = 0; idx < routers.length; ++idx) {
      Pair<Object, RouterProc> p = routers[idx];
      var f = p.f;
      if (f is String ? uri.startsWith(f) : (f as RegExp).hasMatch(uri))
        if (!p.s(data))
          break;
    }

    return true;
  }

}
