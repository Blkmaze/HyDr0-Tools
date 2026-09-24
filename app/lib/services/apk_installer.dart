import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads whatever APK lives at [url] into the app's cache and hands the
/// file straight to Android's own package installer -- the same trick
/// HyDr02's self-updater uses, since a raw browser-style download (launchUrl)
/// has nothing to catch it on a Fire Stick with no browser installed.
///
/// Requires REQUEST_INSTALL_PACKAGES in the manifest (added by brand.py). On
/// first use Android asks the user to allow this app to install unknown
/// apps -- that's the system's own prompt, not ours, and it's expected.
class ApkInstaller {
  /// Reports progress in 0.0-1.0 as the download streams in. Throws with a
  /// readable message on any failure. Resolves once the installer has been
  /// launched -- the actual install happens in Android's own UI from there.
  static Future<void> fetchAndInstall(
    String url, {
    required void Function(double progress) onProgress,
  }) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      throw Exception('That doesn\'t look like a valid http(s) URL.');
    }

    final name = _fileNameFor(uri);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    if (await file.exists()) await file.delete();

    final client = http.Client();
    try {
      final req = http.Request('GET', uri);
      final resp = await client.send(req).timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        throw Exception('Download failed (HTTP ${resp.statusCode})');
      }
      final total = resp.contentLength ?? 0;
      var received = 0;
      var lastPct = -1;
      final sink = file.openWrite();
      try {
        await for (final chunk in resp.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) {
            final pct = (received * 100 ~/ total);
            if (pct != lastPct) { lastPct = pct; onProgress((received / total).clamp(0.0, 1.0)); }
          }
        }
      } finally {
        await sink.close();
      }
      if (total > 0 && received < total) {
        throw Exception('Download ended early (${_mb(received)} of ${_mb(total)}) -- check the connection and try again');
      }
    } finally {
      client.close();
    }

    final result = await OpenFilex.open(file.path, type: 'application/vnd.android.package-archive');
    if (result.type != ResultType.done) {
      throw Exception(
        'Downloaded, but the installer would not open (${result.message}). '
        'Enable "Install unknown apps" for this app in your device settings, then try again.',
      );
    }
  }

  /// Best-effort filename from the URL's last path segment; falls back to a
  /// generic name for URLs that don't end in something .apk-shaped (some
  /// download hosts redirect through a path with no extension at all).
  static String _fileNameFor(Uri uri) {
    final last = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    if (last.toLowerCase().endsWith('.apk') && last.length > 4) return last;
    return 'download-${DateTime.now().millisecondsSinceEpoch}.apk';
  }

  static String _mb(int b) => '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
}
