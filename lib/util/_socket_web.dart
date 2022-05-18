
class MessageEvent {
  dynamic data;
}

class WebSocket {
  static const int OPEN = 1;

  int readyState = 0;
  String? binaryType;

  WebSocket(String addr) {
    throw UnimplementedError("Should use web imp for web.");
  }

  Stream<MessageEvent> get onMessage {
    throw UnimplementedError("Should use web imp for web.");
  }

  void close() { }

  void send(dynamic data) { }
}