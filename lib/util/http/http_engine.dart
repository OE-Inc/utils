/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:native_http/native_http.dart';
import 'package:utils/util/i18n.dart';
import 'package:native_http/native_http.dart' as native_http;
import 'package:utils/util/running_env.dart';
import 'package:utils/util/storage/index.dart';
import 'package:lehttp_overrides/lehttp_overrides.dart';

import '../log.dart';
import 'http_request.dart';
import 'http_response.dart';
import 'method.dart';

extension MapQueryExt on Map {
  List<String> toQuery() {
    List<String> qs = [];
    for (var key in keys) {
      var data = this[key];

      var ks = key is String ? key : jsonEncode(key);
      var vs = data is String ? data : jsonEncode(data);
      qs.add("${Uri.encodeQueryComponent(ks)}=${Uri.encodeQueryComponent(vs)}");
    }

    return qs;
  }
}

abstract class HttpEngine {
  var counter = 1;

  static bool get shouldUseNativeEngine => RunningEnv.isIOS
      || (RunningEnv.androidSdkInt ?? AndroidSdkInt.Android_8_0) <= AndroidSdkInt.Android_7_1
  ;

  static final HttpEngine engine = shouldUseNativeEngine ? _NativeEngine() : _DioEngine();

  void prepare(HttpRequest request, bool mergeQuery) {
    var headers = request.headers;
    var locale = I18N.locale;

    if(headers == null) {
      request.headers = headers = Map();
    }

    if(!headers.containsKey("Accept-Language") && locale != null) {
      headers["Accept-Language"] = locale.toString();
    }

    if(!headers.containsKey("content-type")) {
      headers["content-type"] = "application/json";
    }

    if (!mergeQuery || request.method != Method.GET)
      return;

    var queryParams = request.queryParams;
    var url = request.url;
    var data = request.data;

    var qs = {if (data != null) ...data, if (queryParams != null) ...queryParams};;
    if (qs.length > 0) {
      var allStringValue = qs.values.any((v) => v != null && !(v is String || v is num || v is bool));
      request.url = "$url${url.contains('?') ? "&" : "?"}${allStringValue ? qs.toQuery().join('&') : "body=${Uri.encodeQueryComponent(jsonEncode(qs))}"}";
    }

    // request.data = request.queryParams = null;
  }

  Future<HttpResponse> execute(HttpRequest request);
}

class _DioEngine extends HttpEngine {

  static const _TAG = "HttpEngine(Dio)";

  var _counter = 1;

  Dio _dio = Dio();

  _DioEngine(): super() {
    if (!RunningEnv.isWeb) HttpOverrides.global = LEHttpOverrides();
  }

  @override
  Future<HttpResponse> execute(HttpRequest request) async {
    prepare(request, false);

    int seq = _counter++;

    var headers = request.headers;
    var methodName = request.method.name;
    var queryParams = request.queryParams;
    var url = request.url;
    var data = request.data;

    Log.v(_TAG, () => "Do http request [$seq] $methodName $url\nheaders: $headers\nqueryParameters: $queryParams\ndata: ${jsonEncode(data)}");

    var rsp = HttpResponse();
    try {
      var response = await _dio.request(
          url,
          queryParameters: queryParams,
          options: Options(
            method: methodName,
            headers: headers,
            responseType: request.json ? ResponseType.json : ResponseType.bytes,
            sendTimeout: request.sendTimeout == null ? null : Duration(milliseconds: request.sendTimeout!),
            receiveTimeout: request.receiveTimeout == null ? null : Duration(milliseconds: request.receiveTimeout!),
          ),
          data: data,
          onSendProgress: request.onSendProgress ?? (count, total) { },
          onReceiveProgress: request.onReceiveProgress ?? (count, total) { }
      );

      rsp.code = response.statusCode;
      rsp.headers = response.headers.map;
      rsp.response = response.data is Map ? response.data : {};

      if (response.data is Uint8List)
        rsp.body = response.data;

      if (!(response.data is Map<String, dynamic>) && request.json) {
        rsp.code = HttpResponse.NOT_JSON;
        Log.e(_TAG, () => "Finish http request[$seq] with error: Response is not json");

        return rsp;
      }
    } on DioException catch(error, s) {
      Log.e(_TAG, () => "Finish http request[$seq] with error: $error.");
      switch(error.type) {
        case DioExceptionType.sendTimeout:
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          rsp.code = HttpResponse.TIMEOUT;
          break;

        case DioExceptionType.cancel:
          rsp.code = HttpResponse.CANCEL;
          break;

        case DioExceptionType.badCertificate:
        case DioExceptionType.badResponse:
          rsp.code = error.response?.statusCode ?? HttpResponse.HTTP_FAILED;
          break;

        default:
          rsp.code = HttpResponse.NETWORK_FAILED;
          break;
      }
      rsp.response = { 'reason': "$error", };
    } catch (e, s) {
      rsp.code = HttpResponse.NETWORK_FAILED;
      rsp.response = { 'reason': "$e", };

      Log.e(_TAG, () => "Finish http request[$seq] with other error: $e, stack: $s");
    }

    Log.v(_TAG, () => "Finish http request[$seq]: $rsp");
    return rsp;
  }
}


class _NativeEngine extends HttpEngine {

  static const _TAG = "HttpEngine(Native)";

  var _counter = 1;

  @override
  Future<HttpResponse> execute(HttpRequest request) async {
    prepare(request, true);

    int seq = _counter++;

    var headers = request.headers;
    var methodName = request.method.name;
    var queryParams = request.queryParams;
    var url = request.url;
    var data = request.data;

    Log.v(_TAG, () => "Do http request [$seq] $methodName $url\nheaders: $headers\nqueryParameters: $queryParams\ndata: $data");

    var rsp = HttpResponse();
    try {
      var response = await native_http.request(
        url: url,
        method: methodName,
        headers: headers ?? {},
        body: request.allowBody ? jsonEncode({if (data != null) ...data, if (queryParams != null) ...queryParams}).utf8Bytes : Uint8List(0),
      );

      rsp.code = response.code;
      rsp.body = response.body;
      if (request.json)
        rsp.response = response.getJson();
    } catch (e, s) {
      rsp.code = HttpResponse.NETWORK_FAILED;
      rsp.response = { 'reason': "$e", };
      Log.e(_TAG, () => "Finish http request[$seq] with error: $e, stack: $s");
    }

    Log.v(_TAG, () => "Finish http request[$seq], code: ${rsp.code}\nheaders: ${rsp.headers}\ndata:${rsp.response}");
    return rsp;
  }
}


class SimpleNativeHttpEngine {

  static Future<NativeResponse> execute(String method, String url, { Map<String, String>? headers, Uint8List? body, }) {
    return native_http.request(
      url: url,
      method: method,
      headers: headers ?? {},
      body: body ?? Uint8List(0),
    );
  }

}