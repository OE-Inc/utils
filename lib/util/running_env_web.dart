

import 'running_env.dart';
import 'dart:html';

class RunningEnvWeb {

  static bool get isWebWeiXin {
    if (!RunningEnv.isWeb)
      return false;

    return (window as dynamic).__wxjs_environment == 'miniprogram';
  }

}