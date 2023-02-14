
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

import 'utils.dart';

class Qpt {

  @protected
  List<int>     stamps = [];
  int           interval;

  @protected
  double get    intervalSeconds => interval / 1000.0;

  Qpt(this.interval);

  void add() {
    stamps.add(utc());
    // print('added: $this');
    clearOld();
  }

  void clearOld() {
    var s = utc();
    while (stamps.isNotEmpty && s - stamps.first > interval) {
      // print('removed: ${stamps.first}');
      stamps.removeAt(0);
    }
  }

  double get qps {
    clearOld();
    return stamps.length.toDouble() / intervalSeconds;
  }

  double get lastQps {
    clearOld();
    var s = utc();
    int offs = stamps.lastIndexWhere((element) => s - element > 1000);

    return (stamps.length - (offs > 0 ? offs : 0)).toDouble();
  }

  @override
  String toString() {
    return "QPS[${lastQps.toStringAsFixed(1)}]/QPST[${qps.toStringAsFixed(1)}]";
  }

}