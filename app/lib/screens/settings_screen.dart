import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/catalog_api.dart';
import '../services/store_prefs.dart';
import '../services/self_update.dart';

/// Where you point this device at your own Maze-Tools Store (NAS/Funnel
/// URL), test that connection, and check for app updates. Nothing here is
/// pre-filled -- same "ships empty" rule as the rest of the app.
class SettingsScreen extends StatefulWidget {
  final VoidCallback onStoreChanged;
  const SettingsScreen({super.key, required this.onStoreChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = TextEditingController();
  String? _testResult;
  bool _testing = false;
  bool _busy = false;
  double _progress = 0;
  String? _updateStatus;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _load();
    _loadVersion();
  }

  Future<void> _load() async {
    final url = await StorePrefs.getBaseUrl();
    if (mounted && url != null) setState(() => _controller.text = url);
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = 'v${info.version} (build ${info.buildNumber})');
  }

  Future<void> _save() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;
    await StorePrefs.setBaseUrl(url);
    widget.onStoreChanged();
    await _test();
  }

  Future<void> _test() async {
    setState(() { _testing = true; _testResult = null; });
    try {
      final apps = await CatalogApi.fetchApps();
      if (mounted) setState(() => _testResult = 'Connected -- ${apps.length} app(s) in the catalog.');
    } catch (e) {
      if (mounted) setState(() => _testResult = e.toString());
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _updateStatus = 'Checking for Maze-Tools updates…');
    try {
      final update = await SelfUpdateService.check();
      if (update == null) {
        if (mounted) setState(() => _updateStatus = 'Maze-Tools is up to date.');
        return;
      }
      if (!mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Update available'),
          content: Text('Build ${update.build} is available. Install it now?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Install')),
          ],
        ),
      );
      if (go != true) return;
      setState(() { _busy = true; _progress = 0; _updateStatus = 'Downloading update…'; });
      await SelfUpdateService.downloadAndInstall(update, onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      });
      if (mounted) setState(() => _updateStatus = 'Installer launched -- finish the update on screen.');
    } catch (e) {
      if (mounted) setState(() => _updateStatus = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text('Your Maze-Tools Store', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                const Text(
                  'The NAS/Funnel address of your own Maze-Tools Store backend -- '
                  'this is what the Featured row, Categories, and code entry all '
                  'talk to.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Store URL',
                    hintText: 'https://your-tailnet-name.ts.net',
                    prefixIcon: Icon(Icons.dns),
                  ),
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  FilledButton.icon(
                    onPressed: _testing ? null : _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _testing ? null : _test,
                    icon: const Icon(Icons.wifi_tethering),
                    label: const Text('Test connection'),
                  ),
                ]),
                if (_testResult != null) ...[
                  const SizedBox(height: 10),
                  Text(_testResult!, style: const TextStyle(color: Colors.white70)),
                ],
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text('App updates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                Row(children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _checkForUpdates,
                    icon: const Icon(Icons.system_update_alt),
                    label: const Text('Check for updates'),
                  ),
                  const SizedBox(width: 14),
                  if (_busy) Expanded(child: LinearProgressIndicator(value: _progress > 0 ? _progress : null)),
                ]),
                if (_updateStatus != null) ...[
                  const SizedBox(height: 10),
                  Text(_updateStatus!, style: const TextStyle(color: Colors.white70)),
                ],
                const SizedBox(height: 24),
                Text(_version, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
