import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// One previously-used install link, kept purely as a local convenience so
/// you're not retyping the same URL every time you reinstall something.
/// Nothing here is seeded -- a fresh install of this app has an empty list,
/// same as HyDr02 ships with no servers pre-filled in.
class HistoryEntry {
  final String url;
  final String label;
  final int lastUsed; // millisecondsSinceEpoch

  const HistoryEntry({required this.url, required this.label, required this.lastUsed});

  Map<String, dynamic> toJson() => {'url': url, 'label': label, 'lastUsed': lastUsed};
  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        url: j['url'] ?? '',
        label: j['label'] ?? '',
        lastUsed: (j['lastUsed'] as num?)?.toInt() ?? 0,
      );
}

class InstallHistory {
  static const _key = 'install_history_v1';
  static const _max = 25;

  static Future<List<HistoryEntry>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final entries = list.map(HistoryEntry.fromJson).toList();
      entries.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
      return entries;
    } catch (_) {
      return [];
    }
  }

  static Future<void> remember(String url, {String label = ''}) async {
    final p = await SharedPreferences.getInstance();
    final entries = await load();
    entries.removeWhere((e) => e.url == url);
    entries.insert(0, HistoryEntry(url: url, label: label, lastUsed: DateTime.now().millisecondsSinceEpoch));
    final trimmed = entries.take(_max).toList();
    await p.setString(_key, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  static Future<void> forget(String url) async {
    final p = await SharedPreferences.getInstance();
    final entries = await load();
    entries.removeWhere((e) => e.url == url);
    await p.setString(_key, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
