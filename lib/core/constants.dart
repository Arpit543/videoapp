import 'package:shared_preferences/shared_preferences.dart';

class Constants {
  static const isLogin = "isLogin";
  static const email = "email";
  static const name = "name";
  static const userId = "userId";

  static late final SharedPreferences _prefs;

  ///   Initialize Preferences
  static Future<SharedPreferences> init() async => _prefs = await SharedPreferences.getInstance();

  ///   Set Methods
  static Future<bool> setBool(String key, bool value) async => _prefs.setBool(key, value);
  static Future<bool> setString(String key, String value) async => _prefs.setString(key, value);

  ///   Get Methods
  static bool getBool(String key) => _prefs.getBool(key) ?? false;
  static String? getString(String key) => _prefs.getString(key);

  ///   Clear All Preference
  static Future<bool> clear() async {
    await _prefs.remove(isLogin);
    await _prefs.remove(email);
    await _prefs.remove(name);
    await _prefs.remove(userId);
    return true;
  }
}
