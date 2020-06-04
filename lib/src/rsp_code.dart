class NetworkLocal {
  static const UNREACHABLE = -1;
  static const UNKNOWN = -2;
  static const RESPONSE_NOT_JSON = -3;
  static const IO_ERROR = -4;
  static const FORMAT_ERROR = -5;
  static const NO_RSP_CODE = -6;
  static const RSP_INVALID_TOKEN = -7;
  static const RSP_INVALID_USERID = -8;
  static const PARAM_ENCODE_ERROR = -9;
  static const SHARE_MUST_LOGIN = -10;

  static const int NETWORK_FAILED = -11;
  static const int HTTP_FAILED = -12;
  static const int TIMEOUT = -13;
  static const int NOT_LOGIN = -13;
}

class Transaction {
  static const TRANS_RET_SUCC = 0;
  static const TRANS_RET_TIMEOUT = 1;
  static const TRANS_RET_INTERNAL_ERROR = 2;
  static const TRANS_RET_REJECTED = 3;
  static const TRANS_RET_PARAM_ERROR = 4;
  static const TRANS_RET_FAILED = 5;
  static const TRANS_RET_FULL = 6;
  static const TRANS_RET_NOT_EXIST = 7;
  static const TRANS_RET_ALREADY_EXIST = 8;
  static const TRANS_RET_PERMISSION_DENIED = 9;
  static const TRANS_RET_DEST_NOT_RESPONSE = 10;
  static const TRANS_RET_NOT_SUPPORT = 11;
  static const TRANS_RET_NULL_NETWORK = 12;
  static const TRANS_RET_DEVICE_PROTOCOL_RSPCODE = 193;
}

class Base {
  static const OK = 0;
  static const DATA_FORMAT_ERROR = 10000;
  static const PASSWORD_FORMAT_ERROR = 11001;
  static const EMAIL_FORMAT_ERROR = 11002;
  static const PHONE_FORMAT_ERROR = 11003;
  static const DATA_CONTENT_ERROR = 20000;
  static const VERIFICATION_CODE_ERROR = 21001;
  static const ACTIVATION_CODE_ERROR = 21002;
  static const OPERATION_TOO_OFTEN = 21003;
  static const APP_CLIENT_VERIFY_FAILED = 21004;
  static const LOGIC_ERROR = 30000;
  static const NOT_FOUND = 31000;
  static const USER_NOT_FOUND = 31001;
  static const LOGIN_ID_NOT_FOUND = 31002;
  static const USER_ID_NOT_FOUND = 31003;
  static const EMAIL_IS_REGISTERED = 31004;
  static const PHONE_IS_REGISTERED = 31005;
  static const APP_CLIENT_ID_NOT_REGISTERED = 31006;
  static const APP_CLIENT_NOT_READY = 31007;
  static const APP_CLIENT_STATUS_ERROR = 31008;
  static const ALREADY_EXISTS = 31010;
  static const TOKEN_INVALID = 32001;
  static const TOKEN_PERMISSION_NOT_ENOUGH = 32002;
  static const NOT_PERMITTED_FOR_CURRENT_USER = 32003;
  static const TOKEN_REQUIRED = 32004;
  static const ACCESS_TOKEN_REQ = 32005;
  static const AUTH_TOKEN_REQ = 32006;
  static const REFRESH_TOKEN_REQ = 32007;
  static const ENV_REQ = 32008;
  static const ROBOT_ENV_REQ = 32009;
  static const OWNER_ENV_REQ = 32010;
  static const ENV_INVALID = 32011;
  static const ROBOT_ENV_INVALID = 32012;
  static const OWNER_ENV_INVALID = 32013;
  static const USER_STATUS_INVALID = 32100;
  static const STATUS_INVALID = 32101;
  static const PASSWORD_INCORRECT = 33001;
  static const FORGOTTEN_PASSWORD_IS_NOT_INVOKED = 33002;
  static const TOO_MANY = 34000;
  static const OAUTH = 40000;
  static const OAUTH_TOKEN_NOT_FIND = 40001;
  static const OAUTH_TOKEN_INVALID = 40002;
  static const OUT_OF_LIMIT = 51000;
  static const TOO_FREQUENT = 51010;
  static const OUT_OF_RSC_LIMIT = 51011;
  static const OUT_OF_DATE = 51020;
  static const NOT_SUPPORTED = 52010;
  static const SYSTEM_ERROR = 90000;
  static const EMAIL_SYSTEM_ERROR = 90001;
  static const MSG_SYSTEM_ERROR = 90002;
  static const MYSQL_ERROR = 91000;
  static const MYSQL_DATA_IS_LOCKED = 91001;
  static const MONGODB_ERROR = 92000;
  static const REDIS_ERROR = 93000;
  static const BINARY_SERVER_ERROR = 98000;
  static const OTHER_ERROR = 99999;
}

class Network {
  static const NETWORK_ID_NOT_FOUND = 231001;
  static const NETWORK_ID_ALREADY_EXISTS = 231002;
  static const USER_ID_NOT_FOUND = 231003;
  static const USER_ID_ALREADY_EXISTS = 231004;
  static const SHARE_ID_NOT_FOUND = 231005;
  static const DEVICE_ID_NOT_FOUND = 231006;
  static const GROUP_ID_NOT_FOUND = 231007;
  static const LAN_ID_NOT_FOUND = 231008;
  static const DEVICE_IS_NOT_ONLINE = 231009;
  static const ROUTE_NOT_FOUND = 231010;
  static const NAME_TOO_LONG = 231011;
  static const NO_AUTHORITY = 232001;
  static const PASSWORD_INCORRECT = 233001;
  static const TRANS_URI_NOT_FOUND = 281001;
  static const TRANS_CFG_NOT_FOUND = 281002;
  static const TRANS_CFG_ALREADY_EXISTS = 281003;
  static const SHORT_ID_ALREADY_EXISTS = 281004;
  static const TRANS_URI_REPLACE_REJECT = 282002;
}

class Device {
  static const DEVICE_OFFLINE = 610000;
}

class DeviceControl {
  static const NULL_ADDRESS = -100;
  static const INVALID_ADDRESS = -101;
  static const NOT_CONNECTED = -102;
  static const NO_RESPONSE = -103;
  static const RSP_CODE_INCORRECT = -104;
  static const INVALID_NETWORK_ACCESS_INFO = -105;
  static const NETWORK_ACCESS_FAILED = -106;
  static const SESSION_LOCKED = -107;
  static const NO_BASE_DEVICE = -108;
  static const PARENT_DEVICE_NOT_EXIST = -109;
  static const DEVICE_PARAM_ERROR = -110;
  static const DEVICE_ID_INVALID = -111;
  static const DEVICE_NOT_EXIST = -112;
}

class GroupControl {
  static const DELETE_NOT_EMPTY_GROUP = -250;
  static const GROUP_NOT_EXIST = -251;
}

class Scene {
  static const SCENE_NOT_EXIST = -450;
}

class Sns {
  static const GROUP_ID_NOT_FOUND = 531001;
  static const GROUP_ID_ALREADY_EXISTS = 531002;
  static const USER_ID_NOT_FOUND = 531003;
  static const USER_ID_ALREADY_EXISTS = 531004;
  static const NO_AUTHORITY = 532001;
  static const GROUP_BIND_IN_NETWORK = 532002;
  static const OWNER_CAN_NOT_QUIT = 532003;
}

class TagConfig {
  static const TAG_NOT_EXIST = -400;
}

class Storage {
  static const CLEAR_OLD_FAILED = -150;
  static const FAILED_TO_SAVE = -151;
  static const DEVICE_SLOT_CONFIG_NOT_EXIST = -152;
}

class Rsc {
  static const NOT_FOUND = 331001;
  static const APP_CONFIG_NOT_FOUND = 331002;
  static const APP_NETWORK_CONFIG_NOT_FOUND = 331003;
  static const NO_AUTHORITY = 332001;
}

class Runtime {
  static const NO_BASE_DEVICE = -200;
  static const PARENT_DEVICE_NOT_EXIST = -201;
  static const UNSUPPORTED_ENCODING = -202;
  static const NETWORK_IS_NULL = -203;
  static const NETWORK_NOT_THE_SAME = -204;
  static const ASSIGN_SCENE_SHORTID_TIMEOUT = -205;
}

class OperationNotSupport {
  static const ADD_VIRTUAL_TO_GROUP = -300;
  static const ADD_VIRTUAL_TO_NON_SLAVE = -301;
  static const DEVICE_NOT_SUPPORT_GROUPING = -302;
  static const DEVICE_GROUP_MAX = -303;
  static const DEVICE_NO_SUPPORT_LOCAL_SCENE = -304;
  static const DO_NOT_DELETE_GROUP_ALL = -305;
}

class ParamError {
  static const GROUP_INDEX_OUT_OF_RANGE = -350;
}