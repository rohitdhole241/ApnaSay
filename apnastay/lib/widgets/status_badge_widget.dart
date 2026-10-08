import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum BadgeType { verified, available, occupied, active, paused, matched, new_ }

class StatusBadgeWidget extends StatelessWidget {
  final BadgeType type;
  final String? customLabel;

  const StatusBadgeWidget({super.key, required this.type, this.customLabel});

  @override
  Widget build(BuildContext context) {
    final config = _config();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.icon != null) ...[
            Icon(config.icon, size: 11, color: config.fg),
            const SizedBox(width: 3),
          ],
          Text(
            customLabel ?? config.label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: config.fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _config() {
    switch (type) {
      case BadgeType.verified:
        return _BadgeConfig(
          bg: const Color(0xFFE3F0FF),
          fg: const Color(0xFF1565C0),
          label: 'Verified',
          icon: Icons.verified_rounded,
        );
      case BadgeType.available:
        return _BadgeConfig(
          bg: const Color(0xFFE8F5ED),
          fg: const Color(0xFF2E6F40),
          label: 'Available',
          icon: Icons.circle,
        );
      case BadgeType.occupied:
        return _BadgeConfig(
          bg: const Color(0xFFFFF0EA),
          fg: const Color(0xFFE8622A),
          label: 'Occupied',
          icon: Icons.circle,
        );
      case BadgeType.active:
        return _BadgeConfig(
          bg: const Color(0xFFE8F5ED),
          fg: const Color(0xFF2E6F40),
          label: 'Active',
          icon: Icons.circle,
        );
      case BadgeType.paused:
        return _BadgeConfig(
          bg: const Color(0xFFF5F5F5),
          fg: const Color(0xFF9E9E9E),
          label: 'Paused',
          icon: Icons.pause_circle_outline,
        );
      case BadgeType.matched:
        return _BadgeConfig(
          bg: const Color(0xFFE6F2F5),
          fg: const Color(0xFF4A7C8E),
          label: 'Matched',
          icon: Icons.favorite_rounded,
        );
      case BadgeType.new_:
        return _BadgeConfig(
          bg: const Color(0xFFFFF0EA),
          fg: const Color(0xFFE8622A),
          label: 'New',
        );
    }
  }
}

class _BadgeConfig {
  final Color bg;
  final Color fg;
  final String label;
  final IconData? icon;
  _BadgeConfig({
    required this.bg,
    required this.fg,
    required this.label,
    this.icon,
  });
}
