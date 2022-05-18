



import 'package:android_multicast_lock/android_multicast_lock.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:utils/util/bus.dart';

import 'log.dart';

export 'package:connectivity_plus/connectivity_plus.dart';

const _TAG = "ConnectivityDetector";

class ConnectivityDetector {

  var _conn = new Connectivity();
  bool connected = false;
  ConnectivityResult? connectivity;
  MulticastLock? multicastLock;

  ConnectivityDetector() {
    _conn.onConnectivityChanged.listen(_onChange);
    _conn.checkConnectivity().then(_onChange);
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