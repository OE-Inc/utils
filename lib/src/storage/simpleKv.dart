import 'package:shared_preferences/shared_preferences.dart';

class SimpleKv {
  static Future save(String key, String val) async {
    var sp = await SharedPreferences.getInstance();
    await sp.setString(key, val);
  }

  static Future<String> get(String key, { String fallback, }) async {
    var sp = await SharedPreferences.getInstance();
    return sp.getString(key) ?? fallback;
  }

  static Future del(String key) async {
    var sp = await SharedPreferences.getInstance();
    await sp.remove(key);
  }
}