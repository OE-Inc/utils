
import 'multi_completer.dart';
import 'unit.dart';

import 'log.dart';
import 'utils.dart';

class TimeStampedTask extends MultiCompleter<void> {

  /// 0.0 - 1.0
  double progress = 0;
  int startUtc = 0;
  int endUtc = 0;

  int get period => (endUtc == 0 ? utc() : endUtc) - (startUtc == 0 ? utc() : startUtc);
  int get totalPeriod => utc() - (startUtc == 0 ? utc() : startUtc);

  bool _canceled = false;
  bool get canceled => _canceled;

  bool get started => startUtc > 0;

  bool get cancelable => !completed && !_canceled;
  bool get processing => started && !completed;
  bool get completed => endUtc > 0;

  bool success = false;
  dynamic error;

  void clearCancel() {
    _canceled = false;
  }

  void cancel() {
    if (completed) {
      throw RuntimeException('should not cancel when complete.');
    }

    if (_canceled)
      throw RuntimeException('should not cancel more times.');

    _canceled = true;
  }

  String progressString() {
    return '${progress.percentString}, ${period.periodString}';
  }

  String moreString() {
    return "";
  }

  @override
  String toString() {
    return "$runtimeType { ${progressString()}, ${ error != null ? ", error: $error" : "" }${moreString()}, }";
  }
}


abstract class TimeStampedTaskManager<ITEM extends TimeStampedTask> extends TimeStampedTask {

  static int _id = 0;

  List<ITEM>    pending = [];
  List<ITEM>    cleaned = [];
  List<ITEM>    failed = [];

  bool          dryRun = false;
  int           seqId = ++_id;

  late String   _TAG;

  int get       length => pending.length + cleaned.length + failed.length;
  bool get      isEmpty => length == 0;
  bool get      isNotEmpty => !isEmpty;

  ITEM operator [](int index) {
    if (index < 0) throw RuntimeException('index should > 0.');
    else if (index < failed.length) return failed[index];
    else if ((index -= failed.length) < pending.length) return pending[index];
    else if ((index -= pending.length) < cleaned.length) return cleaned[index];
    else throw RuntimeException('index out of range: [0, $length)');
  }

  TimeStampedTaskManager() {
    _TAG = '$runtimeType[$seqId]';
  }

  void notifyChanged(bool create);

  Future<void> start() async {
    Log.i(_TAG, () => "start: $this.");

    try {
      startUtc = utc();
      notifyChanged(true);
      await doStart();

      Log.i(_TAG, () => "complete: $this.");
    } catch (e) {
      error = e;

      Log.e(_TAG, () => "failed: $this.", e);
    } finally {
      success = failed.isEmpty && pending.isEmpty;
      endUtc = utc();

      if (!canceled)
        complete(null, error);

      notifyChanged(false);
    }
  }

  @override
  void cancel({ bool throws = false, }) {
    super.cancel();

    complete(null, !throws ? null : PendingListCancelError('Canceled').thrown());
  }

  Future<void> doStart() async {
    await prepare();
    notifyChanged(false);

    await clean();

    if (pending.isEmpty)
      progress = 1.0;

    notifyChanged(false);
  }

  Future<void> clean() async {
    int itemSeq = 0;
    int total = pending.length;
    while (pending.isNotEmpty) {
      ++itemSeq;

      var seq = '[$itemSeq/$total]';

      if (canceled) {
        Log.i(_TAG, () => "$seq canceled: $this.");
        break;
      }

      var item = pending.first;
      item.startUtc = utc();

      try {
        Log.i(_TAG, () => "$seq start item: $item, $this.");

        if (dryRun) {
          Log.v(_TAG, () => '$seq items dryRun: $item, $this.');

          rand.nextBool()
            ? await delay(1000)
            : throw TimeoutError('timeout...')
          ;
        } else {
          await doCleanItem(item);
        }

        item.progress = 1.0;
        item.success = true;

        Log.i(_TAG, () => "$seq item complete: $item, $this.");

        cleaned.add(item);
      } catch (e) {
        item.error = e;

        failed.add(item);
        Log.e(_TAG, () => "$seq item failed: $item, $this.", e);
      } finally {
        item.endUtc = utc();

        pending.remove(item);
        progress = (length - pending.length) / length.toDouble();

        item.complete(null, item.error);
        notifyChanged(false);
      }
    }
  }

  Future<void> doCleanItem(ITEM item);

  Future<void> prepare();

  @override
  String toString() {
    return "$runtimeType { ${progressString()}, }";
  }

}