import 'package:flutter/material.dart';
import '../main.dart' show kAccent;

/// Small pill used for category/version tags and the "NAS-hosted" /
/// "GitHub-verified" / "Updated this week" badges, and the orange
/// "Featured" ribbon on cards.
class BadgeChip extends StatelessWidget {
  final String label;
  final bool solid;
  final IconData? icon;

  const BadgeChip(this.label, {super.key, this.solid = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: solid ? kAccent : const Color(0xFF0E1117),
        borderRadius: BorderRadius.circular(999),
        border: solid ? null : Border.all(color: const Color(0xFF232838)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 11, color: solid ? const Color(0xFF04121C) : Colors.white70),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: solid ? FontWeight.w700 : FontWeight.w500,
            color: solid ? const Color(0xFF04121C) : Colors.white70,
          ),
        ),
      ]),
    );
  }
}
