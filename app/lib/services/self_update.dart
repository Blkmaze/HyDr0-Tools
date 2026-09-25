import 'dart:convert';
import 'dart:ffi' show Abi;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'apk_installer.dart';

/// This app's own GitHub repo. Update this if the repo is ever renamed or
/// forked under a different owner.
const String kRepo = 'Blkmaze/HyDr0-Tools';

class SelfUpdate {
  final int build;
  final String downloadUrl;
  const SelfUpdate({required this.build, required this.downloadUrl});
}

/// Checks this app's own repo for a newer signed build than the one
/// currently running, the same way HyDr02 checks its own releases. Every
/// build publishes a `build-<run number>` tagged release with a universal
/// APK plus one per CPU type; this picks the one that matches the device.
class SelfUpdateService {
  static Future<SelfUpdate?> check() async {
    final info = await PackageInfo.fromPlatform();
    final current = int.tryParse(info.buildNumber) ?? 0;
    if (current <= 0) return null;

    final uri = Uri.parse('https://api.github.com/repos/$kRepo/releases?per_page=30');
    final http.Response r;
    try {
      r = await http.get(uri, headers: const {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      return null; // offline / blocked -- just skip the check
    }
    if (r.statusCode != 200) return null;

    final releases = jsonDecode(r.body) as List;
    SelfUpdate? best;
    for (final rel in releases) {
      final tag = (rel['tag_name'] ?? '').toString();
      final m = RegExp(r'^build-(\d+)$').firstMatch(tag);
      if (m == null) continue;
      final build = int.parse(m.group(1)!);
      if (build <= current) continue;
      if (best != null && build <= best.build) continue;

      final assets = (rel['assets'] as List?) ?? const [];
      String? pick(String wanted) {
        for (final a in assets) {
          if ((a['name'] ?? '').toString() == wanted) return (a['browser_download_url'] ?? '').toString();
        }
        return null;
      }
      // Asset names follow the workflow's `app_name` input, stripped of
      // non-alphanumeric characters -- these must be kept in sync with
      // whatever app_name the build is run with (currently "Maze-Tools").
      final abiName = Abi.current() == Abi.androidArm64 ? 'MazeTools-tv-arm64.apk' : 'MazeTools-tv-arm.apk';
      final url = pick(abiName) ?? pick('MazeTools-tv.apk');
      if (url != null && url.isNotEmpty) best = SelfUpdate(build: build, downloadUrl: url);
    }
    return best;
  }

  static Future<void> downloadAndInstall(SelfUpdate update, {required void Function(double) onProgress}) {
    return ApkInstaller.fetchAndInstall(update.downloadUrl, onProgress: onProgress);
  }
}
