
import 'package:utils/src/i18n.dart';

/// Only used for fast import.
class RspCode {
  static const NetworkLocal = NetworkLocalCode();
  static const Transaction = TransactionCode();
  static const Base = BaseCode();
  static const Network = NetworkCode();
  static const Device = DeviceCode();
  static const DeviceControl = DeviceControlCode();
  static const Sns = SnsCode();
  static const Storage = StorageCode();
  static const Rsc = RscCode();
  static const Runtime = RuntimeCode();
  static const OperationNotSupport = OperationNotSupportCode();
  static const ParamError = ParamErrorCode();

  static String defaultReason(int rspCode, [String message]) {
    return I18N.localString((rspCode >= 0 ? 'rspCode' : "rspCode_") + '${rspCode >= 0 ? rspCode : -rspCode}');
  }

  static String dispMsg(int reason, [String message]) {
    return message ?? reason;
  }

}

extension IntRspCodeExt on int {

  /// return: <pre>
  /// m: if m is provided and is not empty.
  /// defaultReason(): else
  /// </pre>
  String rspCodeMsg([String m]) {
    return RspCode.dispMsg(this, m);
  }

  /// returns the default rspCode reason of this int-rspCode.
  String rspCodeReason([String m]) {
    return RspCode.defaultReason(this, m);
  }

}

class NetworkLocalCode {
  final UNREACHABLE = -1;
  final UNKNOWN = -2;
  final RESPONSE_NOT_JSON = -3;
  final IO_ERROR = -4;
  final FORMAT_ERROR = -5;
  final NO_RSP_CODE = -6;
  final RSP_INVALID_TOKEN = -7;
  final RSP_INVALID_USERID = -8;
  final PARAM_ENCODE_ERROR = -9;
  final SHARE_MUST_LOGIN = -10;
  final RSP_ERROR = -11;

  final NETWORK_FAILED = -11;
  final HTTP_FAILED = -12;
  final TIMEOUT = -13;
  final NOT_LOGIN = -14;

  const NetworkLocalCode();
}

class TransactionCode {
  final TRANS_RET_SUCC = 0;
  final TRANS_RET_TIMEOUT = 1;
  final TRANS_RET_INTERNAL_ERROR = 2;
  final TRANS_RET_REJECTED = 3;
  final TRANS_RET_PARAM_ERROR = 4;
  final TRANS_RET_FAILED = 5;
  final TRANS_RET_FULL = 6;
  final TRANS_RET_NOT_EXIST = 7;
  final TRANS_RET_ALREADY_EXIST = 8;
  final TRANS_RET_PERMISSION_DENIED = 9;
  final TRANS_RET_DEST_NOT_RESPONSE = 10;
  final TRANS_RET_NOT_SUPPORT = 11;
  final TRANS_RET_NULL_NETWORK = 12;
  final TRANS_RET_DEVICE_PROTOCOL_RSPCODE = 193;

  const TransactionCode();
}

class BaseCode {
  final OK = 0;
  final DATA_FORMAT_ERROR = 10000;
  final PASSWORD_FORMAT_ERROR = 11001;
  final EMAIL_FORMAT_ERROR = 11002;
  final PHONE_FORMAT_ERROR = 11003;
  final DATA_CONTENT_ERROR = 20000;
  final VERIFICATION_CODE_ERROR = 21001;
  final ACTIVATION_CODE_ERROR = 21002;
  final OPERATION_TOO_OFTEN = 21003;
  final APP_CLIENT_VERIFY_FAILED = 21004;
  final LOGIC_ERROR = 30000;
  final NOT_FOUND = 31000;
  final USER_NOT_FOUND = 31001;
  final LOGIN_ID_NOT_FOUND = 31002;
  final USER_ID_NOT_FOUND = 31003;
  final EMAIL_IS_REGISTERED = 31004;
  final PHONE_IS_REGISTERED = 31005;
  final APP_CLIENT_ID_NOT_REGISTERED = 31006;
  final APP_CLIENT_NOT_READY = 31007;
  final APP_CLIENT_STATUS_ERROR = 31008;
  final ALREADY_EXISTS = 31010;
  final TOKEN_INVALID = 32001;
  final TOKEN_PERMISSION_NOT_ENOUGH = 32002;
  final NOT_PERMITTED_FOR_CURRENT_USER = 32003;
  final TOKEN_REQUIRED = 32004;
  final ACCESS_TOKEN_REQ = 32005;
  final AUTH_TOKEN_REQ = 32006;
  final REFRESH_TOKEN_REQ = 32007;
  final ENV_REQ = 32008;
  final ROBOT_ENV_REQ = 32009;
  final OWNER_ENV_REQ = 32010;
  final ENV_INVALID = 32011;
  final ROBOT_ENV_INVALID = 32012;
  final OWNER_ENV_INVALID = 32013;
  final USER_STATUS_INVALID = 32100;
  final STATUS_INVALID = 32101;
  final PASSWORD_INCORRECT = 33001;
  final FORGOTTEN_PASSWORD_IS_NOT_INVOKED = 33002;
  final TOO_MANY = 34000;
  final OAUTH = 40000;
  final OAUTH_TOKEN_NOT_FIND = 40001;
  final OAUTH_TOKEN_INVALID = 40002;
  final OUT_OF_LIMIT = 51000;
  final TOO_FREQUENT = 51010;
  final OUT_OF_RSC_LIMIT = 51011;
  final OUT_OF_DATE = 51020;
  final NOT_SUPPORTED = 52010;
  final NOT_ENOUGH = 52020;
  final RSC_NOT_ENOUGH = 52021;
  final AMOUNT_NOT_ENOUGH = 52022;
  final BALANCE_NOT_ENOUGH = 52023;
  final NOT_ALLOWED = 52030;
  final CANNOT_EDIT = 52031;
  final ALREADY_IN_STATE = 52032;
  final NOT_SATISFIED = 52040;
  final TOO_LARGE = 53010;

  final SYSTEM_ERROR = 90000;
  final EMAIL_SYSTEM_ERROR = 90001;
  final MSG_SYSTEM_ERROR = 90002;
  final MYSQL_ERROR = 91000;
  final MYSQL_DATA_IS_LOCKED = 91001;
  final MONGODB_ERROR = 92000;
  final REDIS_ERROR = 93000;
  final BINARY_SERVER_ERROR = 98000;
  final OTHER_ERROR = 99999;

  const BaseCode();
}

class NetworkCode {
  final NETWORK_ID_NOT_FOUND = 231001;
  final NETWORK_ID_ALREADY_EXISTS = 231002;
  final USER_ID_NOT_FOUND = 231003;
  final USER_ID_ALREADY_EXISTS = 231004;
  final SHARE_ID_NOT_FOUND = 231005;
  final DEVICE_ID_NOT_FOUND = 231006;
  final GROUP_ID_NOT_FOUND = 231007;
  final LAN_ID_NOT_FOUND = 231008;
  final DEVICE_IS_NOT_ONLINE = 231009;
  final ROUTE_NOT_FOUND = 231010;
  final NAME_TOO_LONG = 231011;
  final NO_AUTHORITY = 232001;
  final PASSWORD_INCORRECT = 233001;
  final TRANS_URI_NOT_FOUND = 281001;
  final TRANS_CFG_NOT_FOUND = 281002;
  final TRANS_CFG_ALREADY_EXISTS = 281003;
  final SHORT_ID_ALREADY_EXISTS = 281004;
  final TRANS_URI_REPLACE_REJECT = 282002;

  const NetworkCode();
}

class DeviceCode {
  final DEVICE_OFFLINE = 610000;


  const DeviceCode();
}

class DeviceControlCode {
  final NULL_ADDRESS = -100;
  final INVALID_ADDRESS = -101;
  final NOT_CONNECTED = -102;
  final NO_RESPONSE = -103;
  final RSP_CODE_INCORRECT = -104;
  final INVALID_NETWORK_ACCESS_INFO = -105;
  final NETWORK_ACCESS_FAILED = -106;
  final SESSION_LOCKED = -107;
  final NO_BASE_DEVICE = -108;
  final PARENT_DEVICE_NOT_EXIST = -109;
  final DEVICE_PARAM_ERROR = -110;
  final DEVICE_ID_INVALID = -111;
  final DEVICE_NOT_EXIST = -112;


  const DeviceControlCode();
}

class SnsCode {
  final GROUP_ID_NOT_FOUND = 531001;
  final GROUP_ID_ALREADY_EXISTS = 531002;
  final USER_ID_NOT_FOUND = 531003;
  final USER_ID_ALREADY_EXISTS = 531004;
  final NO_AUTHORITY = 532001;
  final GROUP_BIND_IN_NETWORK = 532002;
  final OWNER_CAN_NOT_QUIT = 532003;


  const SnsCode();
}

class StorageCode {
  final CLEAR_OLD_FAILED = -150;
  final FAILED_TO_SAVE = -151;
  final DEVICE_SLOT_CONFIG_NOT_EXIST = -152;


  const StorageCode();
}

class RscCode {
  final NOT_FOUND = 331001;
  final APP_CONFIG_NOT_FOUND = 331002;
  final APP_NETWORK_CONFIG_NOT_FOUND = 331003;
  final NO_AUTHORITY = 332001;


  const RscCode();
}

class RuntimeCode {
  final NO_BASE_DEVICE = -200;
  final PARENT_DEVICE_NOT_EXIST = -201;
  final UNSUPPORTED_ENCODING = -202;
  final NETWORK_IS_NULL = -203;
  final NETWORK_NOT_THE_SAME = -204;
  final ASSIGN_SCENE_SHORTID_TIMEOUT = -205;


  const RuntimeCode();
}

class OperationNotSupportCode {
  final ADD_VIRTUAL_TO_GROUP = -300;
  final ADD_VIRTUAL_TO_NON_SLAVE = -301;
  final DEVICE_NOT_SUPPORT_GROUPING = -302;
  final DEVICE_GROUP_MAX = -303;
  final DEVICE_NO_SUPPORT_LOCAL_SCENE = -304;
  final DO_NOT_DELETE_GROUP_ALL = -305;


  const OperationNotSupportCode();
}

class ParamErrorCode {
  final GROUP_INDEX_OUT_OF_RANGE = -350;


  const ParamErrorCode();
}