import 'package:shared_preferences/shared_preferences.dart';

/// Preference keys shared by startup and the settings UI.
class AppPreferences {
  static const keepAwakeKey = 'keepAwake';

  /// The screen used to stay on while reading; keep that behaviour as the
  /// default and let readers turn it off.
  static Future<bool> keepAwake() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keepAwakeKey) ?? true;
  }

  static Future<void> setKeepAwake(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keepAwakeKey, enabled);
  }
}
