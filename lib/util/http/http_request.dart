/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

import 'method.dart';

class HttpRequest {

  Method method;
  String url;
  Map<String, String>? headers;
  Map<String, dynamic>? data;
  Map<String, dynamic>? queryParams;
  Function(int sent, int total)? onSendProgress;
  Function(int receive, int total)? onReceiveProgress;
  int? sendTimeout;
  int? receiveTimeout;

  bool json = true;

  bool get allowBody => method != Method.GET;

  HttpRequest(this.method, this.url, {
    this.headers,
    this.queryParams,
    this.data,
    this.sendTimeout = 10000,
    this.receiveTimeout = 20000,
  });

  @override
  String toString() {
    return "$runtimeType { HTTP $method $url, data: $data, queryParams: $queryParams, sendTimeout: $sendTimeout, receiveTimeout: $receiveTimeout, headers: $headers }";
  }
}