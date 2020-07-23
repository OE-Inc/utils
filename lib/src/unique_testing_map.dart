
import 'package:utils/src/utils.dart';

class UniqueTestingMap<KEY> {
  @protected
  Map<KEY, bool> map = {};

  void clear() => map.clear();

  bool check(KEY k) {
    if (map.containsKey(k))
      return false;

    return map[k] = true;
  }
}