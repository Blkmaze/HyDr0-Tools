import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'services/apk_installer.dart';
import 'services/history.dart';
import 'services/self_update.dart';

void main() => runApp(const HyDr0ToolsApp());

const Color kAccent = Color(0xFF00B4FF);

class HyDr0ToolsApp extends StatelessWidget {
  const HyDr0ToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyDr0 Tools',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0D12),
        colorScheme: ColorScheme.fromSeed(seedColor: kAccent, brightness: Brightness.dark),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  List<HistoryEntry> _history = [];
  bool _busy = false;
  double _progress = 0;
  String? _status;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = 'v${info.version} (build ${info.buildNumber})');
  }

  Future<void> _loadHistory() async {
    final h = await InstallHistory.load();
    if (mounted) setState(() => _history = h);
  }

  Future<void> _install(String url) async {
    if (url.trim().isEmpty || _busy) return;
    setState(() { _busy = true; _progress = 0; _status = 'Downloading…'; });
    try {
      await ApkInstaller.fetchAndInstall(url, onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      });
      await InstallHistory.remember(url);
      await _loadHistory();
      if (mounted) setState(() => _status = 'Installer launched -- finish the install on screen.');
    } catch (e) {
      if (mounted) setState(() => _status = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _status = 'Checking for HyDr0 Tools updates…');
    try {
      final update = await SelfUpdate.check();
      if (update == null) {
        if (mounted) setState(() => _status = 'HyDr0 Tools is up to date.');
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
      setState(() { _busy = true; _progress = 0; _status = 'Downloading update…'; });
      await SelfUpdate.downloadAndInstall(update, onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      });
      if (mounted) setState(() => _status = 'Installer launched -- finish the update on screen.');
    } catch (e) {
      if (mounted) setState(() => _status = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.install_mobile, color: kAccent),
          const SizedBox(width: 10),
          const Text('HyDr0 Tools'),
        ]),
        actions: [
          IconButton(
            tooltip: 'Check for updates',
            icon: const Icon(Icons.system_update_alt),
            onPressed: _busy ? null : _checkForUpdates,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text(
                'Paste a direct APK download link below and install it. '
                'Nothing is pre-loaded -- this app ships empty, same as any '
                'plain sideload tool.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'APK download URL',
                  hintText: 'https://example.com/app-release.apk',
                  prefixIcon: Icon(Icons.link),
                ),
                onSubmitted: _install,
              ),
              const SizedBox(height: 14),
              Row(children: [
                FilledButton.icon(
                  onPressed: _busy ? null : () => _install(_controller.text),
                  icon: const Icon(Icons.download),
                  label: const Text('Fetch & Install'),
                ),
                const SizedBox(width: 14),
                if (_busy)
                  Expanded(
                    child: LinearProgressIndicator(value: _progress > 0 ? _progress : null),
                  ),
              ]),
              if (_status != null) ...[
                const SizedBox(height: 12),
                Text(_status!, style: const TextStyle(color: Colors.white70)),
              ],
              const SizedBox(height: 28),
              if (_history.isNotEmpty) ...[
                Row(children: [
                  const Text('Recent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  TextButton(
                    onPressed: () async { await InstallHistory.clear(); await _loadHistory(); },
                    child: const Text('Clear'),
                  ),
                ]),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (_, i) {
                      final h = _history[i];
                      return ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(h.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () async { await InstallHistory.forget(h.url); await _loadHistory(); },
                        ),
                        onTap: _busy ? null : () { _controller.text = h.url; _install(h.url); },
                      );
                    },
                  ),
                ),
              ] else
                const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Text(_version, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
