import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/app_entry.dart';
import '../services/apk_installer.dart';
import '../services/history.dart';
import '../widgets/badge_chip.dart';

/// Full detail view for one catalog entry -- what tapping a card in the
/// storefront opens. Shows the metadata the admin dashboard collected
/// (description, version, category, badges) plus two ways to get the app
/// onto a device: install it right here, or show a QR code so it can be
/// grabbed on a phone instead (useful since a Fire TV Cube has no camera to
/// scan a code *with* -- this is the "point a phone at the TV" direction).
class AppDetailScreen extends StatefulWidget {
  final AppEntry app;
  final String? storeHost;

  const AppDetailScreen({super.key, required this.app, required this.storeHost});

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> {
  bool _busy = false;
  double _progress = 0;
  String? _status;

  Future<void> _install() async {
    setState(() { _busy = true; _progress = 0; _status = 'Downloading…'; });
    try {
      await ApkInstaller.fetchAndInstall(widget.app.url, onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      });
      await InstallHistory.remember(widget.app.url, label: widget.app.name);
      if (mounted) setState(() => _status = 'Installer launched -- finish the install on screen.');
    } catch (e) {
      if (mounted) setState(() => _status = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final badges = app.badges(storeHost: widget.storeHost);
    return Scaffold(
      appBar: AppBar(title: Text(app.name)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (app.featured) const BadgeChip('Featured', solid: true, icon: Icons.star),
                  BadgeChip(app.category),
                  if (app.version.isNotEmpty) BadgeChip('v${app.version}'),
                  ...badges.map((b) => BadgeChip(b)),
                  BadgeChip('Code ${app.code}', icon: Icons.dialpad),
                ]),
                const SizedBox(height: 18),
                Text(
                  app.description.isEmpty ? 'No description provided.' : app.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 28),
                Row(children: [
                  FilledButton.icon(
                    autofocus: true,
                    onPressed: _busy ? null : _install,
                    icon: const Icon(Icons.download),
                    label: const Text('Install on this device'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _showQr(context),
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Get link on phone'),
                  ),
                ]),
                if (_busy) ...[
                  const SizedBox(height: 20),
                  LinearProgressIndicator(value: _progress > 0 ? _progress : null),
                ],
                if (_status != null) ...[
                  const SizedBox(height: 14),
                  Text(_status!, style: const TextStyle(color: Colors.white70)),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _showQr(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF151922),
        title: Text(widget.app.name),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: QrImageView(data: widget.app.url, size: 220, backgroundColor: Colors.white),
          ),
          const SizedBox(height: 14),
          const Text(
            'Scan with a phone camera to open the download link there.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
