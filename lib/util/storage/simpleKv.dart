/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

import 'package:shared_preferences/shared_preferences.dart';

class SimpleKv {
  static Future save(String key, String val) async {
    var sp = await SharedPreferences.getInstance();
    await sp.setString(key, val);
  }

  static Future<String?> get(String key, { String? fallback, }) async {
    var sp = await SharedPreferences.getInstance();
    return sp.getString(key) ?? fallback;
  }

  static Future del(String key) async {
    var sp = await SharedPreferences.getInstance();
    await sp.remove(key);
  }
}