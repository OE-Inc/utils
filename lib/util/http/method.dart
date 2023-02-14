/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

enum Method {
  GET, POST, PUT, DELETE, OPTIONS, HEAD, TRACE, CONNECT, PATCH
}

extension MethodExt on Method {

  String get name {
    var string = this.toString();
    var index = string.lastIndexOf(".");
    if(index >= 0) {
      string = string.substring(index + 1);
    }
    return string;
  }

}