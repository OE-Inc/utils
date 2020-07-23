abstract class ExceptionWithMessage implements Exception {
  final String msg;
  ExceptionWithMessage(this.msg);

  String get typeString => '$runtimeType';

  @override
  String toString() => "$typeString: $msg";
}

class IllegalArgumentException extends ExceptionWithMessage {
  IllegalArgumentException(String msg) : super(msg);
}


class SqlException extends ExceptionWithMessage {
  int code;

  SqlException(int code, String msg) : super(msg);

  @override
  String toString() => "$typeString(code: $code): $msg";
}

class RspCodeException implements Exception {
  final String  msg;
  final int     rspCode;

  const RspCodeException(this.rspCode, [this.msg]);

  @override
  String toString() {
    return "RspCodeException { rspCode: $rspCode, msg: $msg }";
  }
}

class RuntimeException extends ExceptionWithMessage {
  RuntimeException(String msg) : super(msg);
}


class BinaryFormatError extends Error {
  String message;

  BinaryFormatError(this.message);

  @override
  String toString() {
    return "BinaryFormatError: $message";
  }
}

class CryptoError extends Error {
  String reason;

  CryptoError(this.reason);

  @override
  String toString() {
    return "CryptoError, reason: $reason.";
  }
}
