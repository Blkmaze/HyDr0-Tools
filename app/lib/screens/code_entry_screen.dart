import 'package:flutter/material.dart';
import '../models/app_entry.dart';
import '../services/apk_installer.dart';
import '../services/catalog_api.dart';
import '../services/history.dart';

/// The power-user entry point, demoted off the home screen per the
/// storefront redesign: type a 6-digit code (matched against the loaded
/// catalog so the app can confirm what it is before installing), or fall
/// back to pasting a direct APK URL the old-fashioned way -- this is the
/// entire original app before the storefront rebuild, kept intact as a
/// secondary path rather than removed.
class CodeEntryScreen extends StatefulWidget {
  final List<AppEntry> catalog;
  const CodeEntryScreen({super.key, required this.catalog});

  @override
  State<CodeEntryScreen> createState() => _CodeEntryScreenState();
}

class _CodeEntryScreenState extends State<CodeEntryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _codeController = TextEditingController();
  final _urlController = TextEditingController();
  List<HistoryEntry> _history = [];
  bool _busy = false;
  double _progress = 0;
  String? _status;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final h = await InstallHistory.load();
    if (mounted) setState(() => _history = h);
  }

  Future<void> _installUrl(String url, {String label = ''}) async {
    if (url.trim().isEmpty || _busy) return;
    setState(() { _busy = true; _progress = 0; _status = 'Downloading…'; });
    try {
      await ApkInstaller.fetchAndInstall(url, onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      });
      await InstallHistory.remember(url, label: label);
      await _loadHistory();
      if (mounted) setState(() => _status = 'Installer launched -- finish the install on screen.');
    } catch (e) {
      if (mounted) setState(() => _status = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _installByCode(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty || _busy) return;
    final match = widget.catalog.where((a) => a.code == code).toList();
    if (match.isNotEmpty) {
      await _installUrl(match.first.url, label: match.first.name);
      return;
    }
    // Not in the loaded catalog (stale fetch, or entered before a refresh)
    // -- fall back to asking the backend to resolve the code directly.
    setState(() { _busy = true; _status = 'Looking up code…'; });
    try {
      final url = await CatalogApi.installUrlForCode(code);
      await _installUrl(url);
    } catch (e) {
      if (mounted) setState(() => _status = e.toString().replaceFirst('Exception: ', ''));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter code / paste URL'),
        bottom: TabBar(controller: _tab, tabs: const [
          Tab(text: 'Enter code'),
          Tab(text: 'Paste URL'),
        ]),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: TabBarView(controller: _tab, children: [
              _codeTab(),
              _urlTab(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _codeTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          'Type the 6-digit code shown for an app (in the admin dashboard, or '
          'wherever you shared it) to install it directly, without browsing.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _codeController,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(fontSize: 22, letterSpacing: 4),
          decoration: const InputDecoration(labelText: 'Install code', prefixIcon: Icon(Icons.dialpad), counterText: ''),
          onSubmitted: _installByCode,
        ),
        Row(children: [
          FilledButton.icon(
            onPressed: _busy ? null : () => _installByCode(_codeController.text),
            icon: const Icon(Icons.download),
            label: const Text('Install'),
          ),
          const SizedBox(width: 14),
          if (_busy) Expanded(child: LinearProgressIndicator(value: _progress > 0 ? _progress : null)),
        ]),
        if (_status != null) ...[
          const SizedBox(height: 12),
          Text(_status!, style: const TextStyle(color: Colors.white70)),
        ],
      ]),
    );
  }

  Widget _urlTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          'Paste a direct APK download link and install it -- for anything not '
          'in your store\'s catalog.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _urlController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'APK download URL',
            hintText: 'https://example.com/app-release.apk',
            prefixIcon: Icon(Icons.link),
          ),
          onSubmitted: (u) => _installUrl(u),
        ),
        const SizedBox(height: 14),
        Row(children: [
          FilledButton.icon(
            onPressed: _busy ? null : () => _installUrl(_urlController.text),
            icon: const Icon(Icons.download),
            label: const Text('Fetch & Install'),
          ),
          const SizedBox(width: 14),
          if (_busy) Expanded(child: LinearProgressIndicator(value: _progress > 0 ? _progress : null)),
        ]),
        if (_status != null) ...[
          const SizedBox(height: 12),
          Text(_status!, style: const TextStyle(color: Colors.white70)),
        ],
        const SizedBox(height: 24),
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
                  title: Text(h.label.isNotEmpty ? h.label : h.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: h.label.isNotEmpty ? Text(h.url, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () async { await InstallHistory.forget(h.url); await _loadHistory(); },
                  ),
                  onTap: _busy ? null : () { _urlController.text = h.url; _installUrl(h.url, label: h.label); },
                );
              },
            ),
          ),
        ],
      ]),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    _codeController.dispose();
    _urlController.dispose();
    super.dispose();
  }
}
