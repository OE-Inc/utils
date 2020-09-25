import 'method.dart';

class HttpRequest {

  Method method;
  String url;
  Map<String, String> headers;
  Map<String, dynamic> data;
  Map<String, dynamic> queryParams;
  Function(int sent, int total) onSendProgress;
  Function(int receive, int total) onReceiveProgress;
  int sendTimeout;
  int receiveTimeout;

  bool get allowBody => method != Method.GET;

  HttpRequest(this.method, this.url, {
    this.headers,
    this.queryParams,
    this.data,
    this.sendTimeout = 10000,
    this.receiveTimeout = 20000,
  });
}