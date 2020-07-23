
import 'utils.dart';

class Interval {
  int lastProc = 0,
      miniInterval = 0;

  Interval(int msMiniGap, [ bool fromNow = false ]) {
    if (msMiniGap < 0)
      throw new IllegalArgumentException(" Must init with a msGap >= 0");

    miniInterval = msMiniGap;
    lastProc = utc() - (fromNow ? 0 : miniInterval);
  }

  bool peekNext() {
    return (utc() - lastProc) >= miniInterval;
  }

  bool passedNext() {
    int currMS = utc();
    if (currMS - lastProc >= miniInterval) {
      lastProc = currMS;
      return true;
    }
    return false;
  }

  void updateToNow() {
    lastProc = utc();
  }

  void reset() {
    lastProc = -miniInterval;
  }

  int lastProcPeroid() {
    return utc() - lastProc;
  }

}