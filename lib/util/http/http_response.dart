/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

import 'dart:typed_data';

import '../rsp_code.dart';

class HttpResponse {

  static final int NETWORK_FAILED = RspCode.NetworkLocal.NETWORK_FAILED;
  static final int HTTP_FAILED = RspCode.NetworkLocal.HTTP_FAILED;
  static final int TIMEOUT = RspCode.NetworkLocal.TIMEOUT;
  static final int CANCEL = RspCode.NetworkLocal.CANCEL;
  static final int NO_RSP_CODE  = RspCode.NetworkLocal.NO_RSP_CODE;
  static final int NOT_JSON = RspCode.NetworkLocal.RESPONSE_NOT_JSON;

  int? code;
  Map<String, List<String>>? headers;
  Map<String, dynamic>? response;
  Uint8List? body;

  get isSuccessful => code != null && code! >= 200 && code! <= 300;

  @override
  String toString() {
    return "$runtimeType { code: $code, length: ${body?.length}, response: $response, headers: $headers }";
  }
}