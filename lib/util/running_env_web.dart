

/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

import 'running_env.dart';
import 'dart:html';

class RunningEnvWeb {

  static bool get isWebWeiXin {
    if (!RunningEnv.isWeb)
      return false;

    return (window as dynamic).__wxjs_environment == 'miniprogram';
  }

}