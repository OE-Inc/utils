

/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

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