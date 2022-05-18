

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