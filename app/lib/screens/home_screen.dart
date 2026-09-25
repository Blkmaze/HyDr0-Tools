import 'package:flutter/material.dart';
import '../main.dart' show kAccent;
import '../models/app_entry.dart';
import '../services/catalog_api.dart';
import '../services/store_prefs.dart';
import '../widgets/app_card.dart';
import 'app_detail_screen.dart';
import 'code_entry_screen.dart';
import 'settings_screen.dart';

const _kAllCategory = 'All';

/// The Maze-Tools storefront: a Featured row up top, Categories as filter
/// chips, and a searchable grid underneath -- codes and raw URLs are still
/// available, just moved to a secondary screen for power users instead of
/// being the front door.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AppEntry> _apps = [];
  List<String> _categories = [];
  String _selectedCategory = _kAllCategory;
  String _query = '';
  bool _searching = false;
  bool _loading = false;
  String? _error;
  String? _storeHost;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final base = await StorePrefs.getBaseUrl();
    if (base == null) {
      if (mounted) setState(() { _error = 'no-store'; });
      return;
    }
    if (mounted) setState(() => _storeHost = Uri.tryParse(base)?.host);
    await _refresh();
  }

  Future<void> _refresh() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([CatalogApi.fetchApps(), CatalogApi.fetchCategories()]);
      final apps = results[0] as List<AppEntry>;
      final cats = results[1] as List<String>;
      if (!mounted) return;
      setState(() {
        _apps = apps;
        _categories = cats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(onStoreChanged: _bootstrap)));
    _bootstrap();
  }

  void _openCode() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CodeEntryScreen(catalog: _apps)));
  }

  void _openApp(AppEntry app) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AppDetailScreen(app: app, storeHost: _storeHost)));
  }

  List<AppEntry> get _visible {
    var list = _apps;
    if (_selectedCategory != _kAllCategory) {
      list = list.where((a) => (a.category.isEmpty ? 'Uncategorized' : a.category) == _selectedCategory).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      list = list.where((a) =>
          a.name.toLowerCase().contains(q) ||
          a.description.toLowerCase().contains(q) ||
          a.category.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  // Only ever rendered when category == All and the search box is empty
  // (see _body), so this doesn't need to account for either filter.
  List<AppEntry> get _featured => _apps.where((a) => a.featured).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.storefront, color: kAccent),
          const SizedBox(width: 10),
          const Text('Maze-Tools'),
        ]),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) { _query = ''; _searchController.clear(); }
            }),
          ),
          IconButton(
            tooltip: 'Enter code / paste URL',
            icon: const Icon(Icons.dialpad),
            onPressed: _openCode,
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_error == 'no-store') return _noStore();
    if (_loading && _apps.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null && _apps.isEmpty) return _errorView();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          if (_searching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search apps by name, category, or keyword…',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ),
          SliverToBoxAdapter(child: _categoryRow()),
          if (_selectedCategory == _kAllCategory && _query.trim().isEmpty && _featured.isNotEmpty) ...[
            _sectionHeader('Featured', Icons.star),
            _grid(_featured),
          ],
          _sectionHeader(
            _selectedCategory == _kAllCategory ? 'All apps' : _selectedCategory,
            Icons.apps,
          ),
          _visible.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _apps.isEmpty
                          ? 'Nothing in the catalog yet -- add apps from the admin dashboard.'
                          : 'No apps match that search.',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              : _grid(_visible),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _categoryRow() {
    final all = [_kAllCategory, ..._categories];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = all[i];
          final selected = cat == _selectedCategory;
          return ChoiceChip(
            label: Text(cat),
            selected: selected,
            selectedColor: kAccent,
            labelStyle: TextStyle(color: selected ? const Color(0xFF04121C) : Colors.white70, fontWeight: FontWeight.w600),
            backgroundColor: const Color(0xFF151922),
            onSelected: (_) => setState(() => _selectedCategory = cat),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Row(children: [
          Icon(icon, size: 16, color: kAccent),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
      ),
    );
  }

  Widget _grid(List<AppEntry> apps) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260,
          mainAxisExtent: 168,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, i) => AppCard(app: apps[i], storeHost: _storeHost, onTap: () => _openApp(apps[i])),
          childCount: apps.length,
        ),
      ),
    );
  }

  Widget _noStore() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.dns, size: 48, color: Colors.white38),
          const SizedBox(height: 16),
          const Text(
            'No Maze-Tools Store configured yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Point this device at your NAS/Funnel URL to see Featured apps and Categories.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            autofocus: true,
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
            label: const Text('Set up store'),
          ),
        ]),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off, size: 48, color: Colors.white38),
          const SizedBox(height: 16),
          Text(_error ?? 'Something went wrong.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          OutlinedButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
