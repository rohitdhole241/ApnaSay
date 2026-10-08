import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../pg_listings_screen.dart';

class PgViewToggleWidget extends StatelessWidget {
  final PgViewMode viewMode;
  final ValueChanged<PgViewMode> onToggle;
  final int resultCount;

  const PgViewToggleWidget({
    super.key,
    required this.viewMode,
    required this.onToggle,
    required this.resultCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      color: AppTheme.background,
      child: Row(
        children: [
          Text(
            '$resultCount PGs found',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceMedium,
            ),
          ),
          const Spacer(),
          Container(
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Row(
              children: [
                _ToggleBtn(
                  icon: Icons.list_rounded,
                  label: 'List',
                  isActive: viewMode == PgViewMode.list,
                  onTap: () => onToggle(PgViewMode.list),
                ),
                _ToggleBtn(
                  icon: Icons.map_rounded,
                  label: 'Map',
                  isActive: viewMode == PgViewMode.map,
                  onTap: () => onToggle(PgViewMode.map),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBrand : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : AppTheme.onSurfaceMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.white : AppTheme.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
