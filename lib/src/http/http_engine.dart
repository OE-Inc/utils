import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../log.dart';
import 'http_request.dart';
import 'method.dart';

import 'http_response.dart';

abstract class HttpEngine {

  Locale _locale;

  static final HttpEngine engine = _DioEngine();

  Future<HttpResponse> execute(HttpRequest request);

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
    if(!headers.containsKey("Accept-Language") && locale != null) {
      headers["Accept-Language"] = locale.toString();
    }

    if(!headers.containsKey("content-type")) {
      headers["content-type"] = "application/json";
    }

    var methodName = request.method.name;
    var queryParams = request.queryParams;
    var url = request.url;
    var data = request.data;

    Log.v(_TAG, "Do http request [$seq] $methodName $url\nheaders: $headers\nqueryParameters: $queryParams\ndata: $data");

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
        Log.e(_TAG, "Finish http request[$seq] with error: Response is not json");
        return myResponse;
      }

      myResponse.response = response.data;
    } on DioError catch(error, s) {
      Log.e(_TAG, "Finish http request[$seq] with DioError: $error, stack: $s");
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
          myResponse.code = HttpResponse.NETWORK_FAILED;
          break;
      }
    } catch (e, s) {
      myResponse.code = HttpResponse.NETWORK_FAILED;
      Log.e(_TAG, "Finish http request[$seq] with error: $e, stack: $s");
    }

    Log.v(_TAG, "Finish http request[$seq], code: ${myResponse.code}\nheaders: ${myResponse.headers}\ndata:${myResponse.response}");
    return myResponse;
  }
}
