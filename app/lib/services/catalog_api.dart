import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_entry.dart';
import 'store_prefs.dart';

class CatalogException implements Exception {
  final String message;
  CatalogException(this.message);
  @override
  String toString() => message;
}

/// Talks to the public, no-auth side of the Maze-Tools Store backend:
/// `/api/apps`, `/api/categories`. This is the storefront's data source --
/// none of this touches `/admin` or the upload/delete routes, which stay
/// Basic-Auth gated and are only ever driven from the web dashboard.
class CatalogApi {
  /// Full catalog, unfiltered -- also what code entry matches against so a
  /// typed code can show the app's name/version before installing anything.
  static Future<List<AppEntry>> fetchApps() async {
    final base = await StorePrefs.getBaseUrl();
    if (base == null) {
      throw CatalogException('No store configured yet -- set it up in Settings.');
    }
    final http.Response r;
    try {
      r = await http.get(Uri.parse('$base/api/apps')).timeout(const Duration(seconds: 12));
    } catch (_) {
      throw CatalogException('Could not reach the store at $base -- check the URL and your connection.');
    }
    if (r.statusCode != 200) {
      throw CatalogException('Store returned an error (HTTP ${r.statusCode}).');
    }
    try {
      final list = jsonDecode(r.body) as List;
      return list.cast<Map<String, dynamic>>().map(AppEntry.fromJson).toList();
    } catch (_) {
      throw CatalogException('Store returned something unexpected -- is that URL really a Maze-Tools Store?');
    }
  }

  static Future<List<String>> fetchCategories() async {
    final base = await StorePrefs.getBaseUrl();
    if (base == null) return const [];
    try {
      final r = await http.get(Uri.parse('$base/api/categories')).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return const [];
      return (jsonDecode(r.body) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  /// The URL a code entry should install -- lets code entry work even for
  /// a code the local catalog fetch didn't happen to include.
  static Future<String> installUrlForCode(String code) async {
    final base = await StorePrefs.getBaseUrl();
    if (base == null) {
      throw CatalogException('No store configured yet -- set it up in Settings.');
    }
    return '$base/api/install/${Uri.encodeComponent(code.trim())}';
  }
}
