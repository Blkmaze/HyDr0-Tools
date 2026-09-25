/// One catalog entry as returned by the backend's public `/api/apps` route.
/// Mirrors `publicView()` in the Maze-Tools Store's server.js -- keep the
/// fields here in sync with that function if the backend response shape
/// ever changes.
class AppEntry {
  final String code;
  final String name;
  final String version;
  final String description;
  final String category;
  final bool featured;
  final String url;
  final String? icon;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppEntry({
    required this.code,
    required this.name,
    required this.version,
    required this.description,
    required this.category,
    required this.featured,
    required this.url,
    this.icon,
    this.createdAt,
    this.updatedAt,
  });

  factory AppEntry.fromJson(Map<String, dynamic> j) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return AppEntry(
      code: (j['code'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      version: (j['version'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      category: (j['category'] ?? 'Uncategorized').toString(),
      featured: j['featured'] == true,
      url: (j['url'] ?? '').toString(),
      icon: (j['icon'] as String?)?.trim().isEmpty ?? true ? null : (j['icon'] as String).trim(),
      createdAt: parseDate(j['createdAt']),
      updatedAt: parseDate(j['updatedAt']),
    );
  }

  /// Rough badges for the storefront cards. Purely cosmetic/informational --
  /// computed client-side from the URL shape and timestamps, nothing the
  /// backend has to track specially.
  List<String> badges({required String? storeHost}) {
    final out = <String>[];
    final u = Uri.tryParse(url);
    if (u != null) {
      if (storeHost != null && u.host == storeHost) {
        out.add('NAS-hosted');
      } else if (u.host.contains('github.com') || u.host.contains('githubusercontent.com')) {
        out.add('GitHub-verified');
      }
    }
    final touched = updatedAt ?? createdAt;
    if (touched != null && DateTime.now().difference(touched) <= const Duration(days: 7)) {
      out.add('Updated this week');
    }
    return out;
  }
}
