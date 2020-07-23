

import 'package:utils/src/socket.dart';

class JsonRpcRequest {
  String  ver;
  String  protocol;

  String  method;
  String  uri;
  String  param;

  int     timeout;
}

class JsonRpcResponse {
  String  encoding;
  String  ver;

  String  code;
  String  param;
}

typedef JsonRpcOnCall = void Function(JsonRpcRequest);

class JsonRpc {
  SocketClient      client;
  JsonRpcOnCall     processor;

  JsonRpc(this.processor);

  Future<JsonRpcResponse> send(JsonRpcRequest request) {
    //
  }

}