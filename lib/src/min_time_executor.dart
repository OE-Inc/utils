
import 'package:utils/src/storage/index.dart';

class MinTimeExecutor {
  int minTime;

  MinTimeExecutor(this.minTime);

  Future<T> wait<T>(Future<T> pending, { int minTime }) async {
    var s = utc();

    var r = await pending;
    var using = utc() - s;

    minTime = minTime ?? this.minTime;
    if (using < minTime)
      await delay(minTime - using);

    return r;
  }

  Future<T> execute<T>(Future<T> Function() run, { int minTime }) {
    return wait(run(), minTime: minTime);
  }
}