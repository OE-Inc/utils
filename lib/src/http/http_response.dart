import '../rsp_code.dart';

class HttpResponse {

  static final int NETWORK_FAILED = RspCode.NetworkLocal.NETWORK_FAILED;
  static final int HTTP_FAILED = RspCode.NetworkLocal.HTTP_FAILED;
  static final int TIMEOUT = RspCode.NetworkLocal.TIMEOUT;
  static final int NO_RSP_CODE  = RspCode.NetworkLocal.NO_RSP_CODE;
  static final int NOT_JSON = RspCode.NetworkLocal.RESPONSE_NOT_JSON;

  int code;
  Map<String, List<String>> headers;
  Map<String, dynamic> response;

  get isSuccessful => code != null && code >= 200 && code <= 300;
}