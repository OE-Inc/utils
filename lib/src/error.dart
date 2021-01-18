
extension ErrorExt on Error {
  thrown() {
    try {
      throw this;
    } catch (e) {
      return e;
    }
  }
}

abstract class ExceptionWithMessage extends Error {
  final String msg;
  ExceptionWithMessage(this.msg);

  @override
  String toString() => "$runtimeType: $msg";
}

String errorMsg(e, [StackTrace trace]) {
  if (e is Error) return "$e\n${e.stackTrace ?? trace ?? StackTrace.current}";
  else return "$e\n${trace ?? StackTrace.current}";
}

class IllegalArgumentException extends ExceptionWithMessage {
  IllegalArgumentException(String msg) : super(msg);
}


class TimeoutError extends ExceptionWithMessage {
  TimeoutError(String msg) : super(msg);
}

class SqlException extends ExceptionWithMessage {
  int code;

  SqlException(int code, String msg) : super(msg);

  @override
  String toString() => "$runtimeType(code: $code): $msg";
}

class RspCodeException extends Error {
  final String  msg;
  final String  reason;
  final         data;
  final int     rspCode;

  RspCodeException(this.rspCode, { this.msg, this.reason, this.data });

  @override
  String toString() {
    return "$runtimeType { rspCode: $rspCode, reason: $reason, msg: $msg, data: $data, }";
  }
}

class RuntimeException extends ExceptionWithMessage {
  RuntimeException(String msg) : super(msg);
}

class NoResourceException<T> extends ExceptionWithMessage {
  T     device;

  NoResourceException(String msg, this.device) : super(msg);
}


class BinaryFormatError<T> extends Error {
  String  message;

  BinaryFormatError(this.message);

  @override
  String toString() {
    return "$runtimeType: $message";
  }
}

class CryptoError extends Error {
  String reason;

  CryptoError(this.reason);

  @override
  String toString() {
    return "$runtimeType, $reason";
  }
}


class NoConnectionError extends Error {
  String reason;

  NoConnectionError(this.reason);

  @override
  String toString() {
    return "$runtimeType, $reason";
  }
}


class MessageBusyError<T> extends Error {
  String  reason;
  T       device;

  MessageBusyError(this.reason, this.device);

  @override
  String toString() {
    return "$runtimeType, $reason";
  }
}


class PendingListFullError extends Error {
  String reason;

  PendingListFullError(this.reason);

  @override
  String toString() {
    return "$runtimeType, $reason";
  }
}

class PendingListCancelError extends Error {
  String reason;

  PendingListCancelError(this.reason);

  @override
  String toString() {
    return "$runtimeType, $reason";
  }
}
