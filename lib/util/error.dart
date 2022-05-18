
extension ErrorExt on Error {
  thrown() {
    try {
      throw this;
    } catch (e) {
      return e;
    }
  }
}

T? _getField<T>(T getter()) {
  try {
    return getter();
  } catch (e) {
    if (e is NoSuchMethodError)
      return null;
    else
      rethrow;
  }
}

abstract class ExceptionWithMessage<T> extends Error {
  final String?   msg;
  final T?        data;

  ExceptionWithMessage(this.msg, { this.data, });

  String? get dataName {
    dynamic d = data;
    if (d == null)
      return null;

    if (d is String)
      return d;

    var name = _getField(() => d.name) ?? _getField(() => d.config.name);
    if (name is Function)
      name = name();

    return name == null ? null : "$name";
  }

  @override
  String toString() => "$runtimeType: $msg";
}

String errorMsg(e, [StackTrace? trace]) {
  if (e is Error) return "$e\n${e.stackTrace}\nWhere:\n${trace ?? StackTrace.current}";
  else return "${e is Exception ? "[tips: Use Error, Not Exception]" : ""}$e\nWhere:\n${trace ?? StackTrace.current}";
}

class TimeoutError extends ExceptionWithMessage {
  int? timeout;

  TimeoutError(String msg, [this.timeout]) : super(msg);

  @override
  String toString() {
    return super.toString() + "[timeout: ${timeout}ms]";
  }
}

class IllegalArgumentException extends ExceptionWithMessage {
  IllegalArgumentException(String msg) : super(msg);
}


class SqlException extends ExceptionWithMessage {
  int code;

  SqlException(this.code, String msg) : super(msg);

  @override
  String toString() => "$runtimeType(code: $code): $msg";
}

class RspCodeException extends ExceptionWithMessage {
  final String? reason;
  final int     rspCode;

  RspCodeException(this.rspCode, { String? msg, this.reason, var data }): super(msg, data: data);

  @override
  String toString() {
    return "$runtimeType { rspCode: $rspCode, reason: $reason, msg: $msg, data: $data, }";
  }
}

class RuntimeException<T> extends ExceptionWithMessage<T> {
  RuntimeException(String msg, { T? data }) : super(msg, data: data);
}

class NoResourceException<T> extends ExceptionWithMessage<T> {
  NoResourceException(String msg, T device) : super(msg, data: device);
}


class BinaryFormatError<T> extends ExceptionWithMessage<T> {
  BinaryFormatError(String msg, { T? data }) : super(msg, data: data);
}

class CryptoError<T> extends ExceptionWithMessage<T> {
  CryptoError(String msg, { T? data }) : super(msg, data: data);
}


class NoConnectionError<T> extends ExceptionWithMessage<T> {
  NoConnectionError(String msg, { T? data }) : super(msg, data: data);
}


class MessageBusyError<T> extends ExceptionWithMessage<T> {
  MessageBusyError(String msg, { T? data }) : super(msg, data: data);
}

class UnsupportedError<T> extends ExceptionWithMessage<T> {
  UnsupportedError(String msg, { T? data }) : super(msg, data: data);
}

class DeviceInvalidError<T> extends ExceptionWithMessage<T> {
  DeviceInvalidError(String msg, { T? data }) : super(msg, data: data);
}


class NotFoundError<T> extends ExceptionWithMessage<T> {
  NotFoundError(String msg, { T? data }) : super(msg, data: data);
}

class NoItemsError<T> extends ExceptionWithMessage<T> {
  NoItemsError(String msg, T data) : super(msg, data: data);
}

class UnimplementedError<T> extends ExceptionWithMessage<T> {
  UnimplementedError([String? msg, T? data]) : super(msg, data: data);
}

class PendingListFullError<T> extends ExceptionWithMessage<T> {
  PendingListFullError(String msg, { T? data }) : super(msg, data: data);
}

class PendingListCancelError<T> extends ExceptionWithMessage<T> {
  PendingListCancelError(String msg, { T? data }) : super(msg, data: data);
}
