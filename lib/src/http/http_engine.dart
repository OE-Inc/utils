import 'dart:io';

import 'package:dio/dio.dart';
import 'package:utils/src/i18n.dart';
import 'package:native_http/native_http.dart' as native_http;
import 'package:utils/src/running_env.dart';
import 'package:utils/src/storage/index.dart';

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

  static final HttpEngine engine = RunningEnv.isAndroid ? _DioEngine() : _NativeEngine();

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

  @override
  Future<HttpResponse> execute(HttpRequest request) async {
    prepare(request, false);

    int seq = _counter++;

    var headers = request.headers;
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
      Log.e(_TAG, "Finish http request[$seq] with error: $error, stack: $s");
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
      Log.e(_TAG, "Finish http request[$seq] with other error: $e, stack: $s");
    }

    Log.v(_TAG, "Finish http request[$seq], code: ${myResponse.code}\nheaders: ${myResponse.headers}\ndata:${myResponse.response}");
    return myResponse;
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

    Log.v(_TAG, "Do http request [$seq] $methodName $url\nheaders: $headers\nqueryParameters: $queryParams\ndata: $data");

    var myResponse = HttpResponse();
    try {
      var response = await native_http.request(
        url: url,
        method: methodName,
        headers: headers ?? {},
        body: request.allowBody ? jsonEncode({if (data != null) ...data, if (queryParams != null) ...queryParams}).utf8Bytes : Uint8List(0),
      );

      myResponse.code = response.code;
      myResponse.response = response.getJson();
    } catch (e, s) {
      myResponse.code = HttpResponse.NETWORK_FAILED;
      Log.e(_TAG, "Finish http request[$seq] with error: $e, stack: $s");
    }

    Log.v(_TAG, "Finish http request[$seq], code: ${myResponse.code}\nheaders: ${myResponse.headers}\ndata:${myResponse.response}");
    return myResponse;
  }
}
