import 'package:flutter/material.dart';
import '../main.dart' show kAccent;
import '../models/app_entry.dart';
import 'badge_chip.dart';
import 'tv_focusable.dart';

/// One tile in a storefront grid -- icon (or generated initials), name,
/// category/version/status badges, and a Featured ribbon when applicable.
class AppCard extends StatelessWidget {
  final AppEntry app;
  final String? storeHost;
  final VoidCallback onTap;

  const AppCard({super.key, required this.app, required this.storeHost, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final badges = app.badges(storeHost: storeHost);
    return TvFocusable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151922),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF232838)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _Icon(app: app),
            const Spacer(),
            if (app.featured) const BadgeChip('Featured', solid: true, icon: Icons.star),
          ]),
          const SizedBox(height: 10),
          Text(app.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            app.description.isEmpty ? ' ' : app.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            BadgeChip(app.category),
            if (app.version.isNotEmpty) BadgeChip('v${app.version}'),
            ...badges.map((b) => BadgeChip(b)),
          ]),
        ]),
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  final AppEntry app;
  const _Icon({required this.app});

  @override
  Widget build(BuildContext context) {
    const size = 44.0;
    if (app.icon != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          app.icon!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initials(size),
        ),
      );
    }
    return _initials(size);
  }

  Widget _initials(double size) {
    final initials = app.name.trim().isEmpty
        ? '?'
        : app.name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0]).join().toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Text(initials, style: const TextStyle(color: Color(0xFF04121C), fontWeight: FontWeight.w800, fontSize: 16)),
    );
  }
}
