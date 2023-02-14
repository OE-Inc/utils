
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

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