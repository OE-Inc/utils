

/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

import 'package:utils/util/simple_interface.dart';

class LazyValue<T> {

  T? _value;
  Callable<T> _getter;

  LazyValue(this._getter);

  T call() => _value ?? _getter();
}

class LazyAsyncValue<T> {

  T? _value;
  Callable<Future<T>> _getter;

  LazyAsyncValue(this._getter);

  Future<T> call() async => _value ?? await _getter();
}