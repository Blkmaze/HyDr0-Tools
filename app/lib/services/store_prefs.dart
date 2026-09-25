import 'package:shared_preferences/shared_preferences.dart';

/// Where this device's copy of Maze-Tools points to find the Maze-Tools
/// Store backend (the NAS/Funnel URL). Nothing is hardcoded/seeded -- on a
/// fresh install this is empty and the app asks for it once, the same
/// "ships empty" philosophy as everything else in this app.
class StorePrefs {
  static const _key = 'store_base_url_v1';

  static Future<String?> getBaseUrl() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.trim().isEmpty) return null;
    return _normalize(raw);
  }

  static Future<void> setBaseUrl(String url) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, _normalize(url));
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }

  /// Strips a trailing slash so callers can safely do '$base/api/apps'.
  static String _normalize(String url) {
    var s = url.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }
}
