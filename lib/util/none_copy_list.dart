

/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

import 'dart:collection';

import 'package:utils/util/error.dart';

class NoneCopyList<E> extends ListMixin<E> {
  List<E> under;
  late int start;
  late int end;

  @override
  late int length;

  NoneCopyList(this.under, [int? start, int? end]) {
    this.start = start ??= 0;
    this.end = end ??= under.length;

    if (start < 0) throw IllegalArgumentException('start($start) should > 0');
    if (end < start) throw IllegalArgumentException('end($end) should larger than start($start).');
    if (end > under.length) throw IllegalArgumentException('end($end) should less than under.length(${under.length}).');

    length = end - start;
  }

  @override
  operator [](int index) {
    return under[start + index];
  }

  @override
  void operator []=(int index, value) {
    under[start + index] = value;
  }

}