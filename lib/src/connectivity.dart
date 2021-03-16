



import 'package:connectivity/connectivity.dart';
import 'package:utils/src/bus.dart';

import 'log.dart';


const _TAG = "ConnectivityDetector";

class ConnectivityDetector {

  var _conn = new Connectivity();
  bool connected = false;
  ConnectivityResult connectivity;

  ConnectivityDetector() {
    _conn.onConnectivityChanged.listen(_onChange);
    _conn.checkConnectivity().then(_onChange);
  }

  _onChange(ConnectivityResult result) {
    if (result == connectivity)
      return;

    Log.i(_TAG, "connectivity changed: $result.");

    connectivity = result;
    connected = result != ConnectivityResult.none;
    bus.fire(result);
  }

}

ConnectivityDetector connectivityDetector = ConnectivityDetector();