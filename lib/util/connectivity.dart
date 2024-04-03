



/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

import 'package:android_multicast_lock/android_multicast_lock.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:utils/util/bus.dart';
import 'package:utils/util/running_env.dart';

import 'log.dart';

export 'package:connectivity_plus/connectivity_plus.dart';

const _TAG = "ConnectivityDetector";

class ConnectivityDetector {

  var _conn = new Connectivity();
  bool connected = false;
  ConnectivityResult? connectivity;
  MulticastLock? multicastLock;

  ConnectivityDetector() {
    try {
      _conn.onConnectivityChanged.listen(_onChangeList);
      _conn.checkConnectivity().then(_onChangeList);
    } catch (e) {
      if (RunningEnv.isDebug) rethrow;
      Log.e(_TAG, () => "ConnectivityDetector() error: ", e);
    }
  }

  _onChangeList(List<ConnectivityResult> results) {
    for (var r in results) {
      _onChange(r);
    }
  }

  _onChange(ConnectivityResult result) {
    if (result == connectivity)
      return;

    Log.i(_TAG, () => "connectivity changed: $result.");

    connectivity = result;
    connected = result != ConnectivityResult.none;

    var ml = multicastLock;
    if (connected && ml == null) {
      ml = multicastLock = MulticastLock();
      ml.acquire()
          .then((_) => Log.d(_TAG, () => 'multicastLock acquire success: $ml.'))
          .catchError((e) => Log.e(_TAG, () => 'multicastLock acquire error: $ml.', e))
      ;

    } else if (!connected && ml != null) {
      ml.release()
          .then((_) => Log.d(_TAG, () => 'multicastLock release success: $ml.'))
          .catchError((e) => Log.e(_TAG, () => 'multicastLock release error: $ml.', e))
      ;
      multicastLock = null;
    }

    bus.fire(result);
  }

}

ConnectivityDetector connectivityDetector = ConnectivityDetector();