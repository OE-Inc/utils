import 'dart:io';

import 'package:better_log/betterlog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:futils/src/http/http_request.dart';
import 'package:futils/src/http/method.dart';

import 'http_response.dart';

abstract class HttpEngine {

  Locale _locale = null;

  static HttpEngine _engine = _DioEngine();

  Future<HttpResponse> execute(HttpRequest request);

  static HttpEngine get engine => _engine;

  set locale(Locale locale) => _locale = locale;
}

class _DioEngine extends HttpEngine {

  static const _TAG = "HttpEngine(Dio)";

  var _counter = 1;

  Dio _dio = Dio();

  @override
  Future<HttpResponse> execute(HttpRequest request) async {

    int seq = _counter ++;

    var headers = request.headers;
    var locale = _locale;
    if(headers == null) {
      headers = Map();
    }
    if(headers.containsKey("Accept-Language") && locale != null) {
      headers["Accept-Language"] = locale.toString();
    }

    if(headers.containsKey("content-type")) {
      headers["content-type"] = "application/json";
    }

    var methodName = _getMethodName(request.method);
    var queryParams = request.queryParams;
    var url = request.url;
    var data = request.data;

    BetterLog.v(_TAG, "Do http request [$seq]\nmethod: $methodName\nurl: $url\nqueryParameters: $queryParams\ndata: $data");

    var myResponse = HttpResponse();
    try {
      var response = await _dio.request(
          url,
          queryParameters: queryParams,
          options: Options(
            method: methodName,
            headers: headers,
            responseType: ResponseType.json,
            sendTimeout: request.sendTimeout,
            receiveTimeout: request.receiveTimeout,
          ),
          data: data,
          onSendProgress: request.onSendProgress ?? (count, total) { },
          onReceiveProgress: request.onReceiveProgress ?? (count, total) { }
      );

      myResponse.code = response.statusCode;
      myResponse.headers = response.headers?.map;

      if(!(response.data is Map<String, dynamic>)) {
        myResponse.code = HttpResponse.NOT_JSON;
        BetterLog.e(_TAG, "Finish http request[$seq] with error: Response is not json");
        return myResponse;
      }

      myResponse.response = response.data;
    } on DioError catch(e, s) {
      var error = e as DioError;
      BetterLog.e(_TAG, "Finish http request[$seq] with error: $e, stack: $s");
      switch(error.type) {
        case DioErrorType.SEND_TIMEOUT:
        case DioErrorType.CONNECT_TIMEOUT:
        case DioErrorType.RECEIVE_TIMEOUT:
          myResponse.code = HttpResponse.TIMEOUT;
          break;

        case DioErrorType.RESPONSE:
          myResponse.code = error.response.statusCode;
          break;
        default:
          break;
      }
    } catch (e, s) {
      myResponse.code = HttpResponse.NETWORK_FAILED;
      BetterLog.e(_TAG, "Finish http request[$seq] with error: $e, stack: $s");
    }

    BetterLog.v(_TAG, "Finish http request[$seq], code: ${myResponse.code}\nheaders: ${myResponse.headers}\ndata:${myResponse.response}");
    return myResponse;
  }
}

String _getMethodName(Method method) {
  var string = method.toString();
  var index = string.lastIndexOf(".");
  if(index >= 0) {
    string = string.substring(index + 1);
  }
  return string;
}
