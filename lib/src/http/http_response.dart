import 'package:futils/src/rsp_code.dart';

class HttpResponse {

  static const int NETWORK_FAILED = NetworkLocal.NETWORK_FAILED;
  static const int HTTP_FAILED = NetworkLocal.HTTP_FAILED;
  static const int TIMEOUT = NetworkLocal.TIMEOUT;
  static const int NO_RSP_CODE  = NetworkLocal.NO_RSP_CODE;
  static const int NOT_JSON = NetworkLocal.RESPONSE_NOT_JSON;

  int code;
  Map<String, List<String>> headers;
  Map<String, dynamic> response;

  get isSuccessful => code != null && code >= 200 && code <= 300;
}