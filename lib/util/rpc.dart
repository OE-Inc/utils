

import 'package:utils/util/socket.dart';

class JsonRpcRequest {
  late  String  ver;
  late  String  protocol;

  late  String  method;
  late  String  uri;
  late  String  param;

  late  int     timeout;
}

class JsonRpcResponse {
  late  String  encoding;
  late  String  ver;

  late  String  code;
  late  String  param;
}

typedef JsonRpcOnCall = void Function(JsonRpcRequest);

class JsonRpc {
  // SocketClient      client;
  JsonRpcOnCall     processor;

  JsonRpc(this.processor);

  // Future<JsonRpcResponse> send(JsonRpcRequest request) {
  // }

}