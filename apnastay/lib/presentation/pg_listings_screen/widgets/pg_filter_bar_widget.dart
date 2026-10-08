import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class PgFilterBarWidget extends StatelessWidget {
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;

  const PgFilterBarWidget({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  static const List<_FilterChipData> _filters = [
    _FilterChipData(label: 'All', icon: Icons.apps_rounded),
    _FilterChipData(label: 'Verified', icon: Icons.verified_rounded),
    _FilterChipData(label: 'Girls', icon: Icons.female_rounded),
    _FilterChipData(label: 'Boys', icon: Icons.male_rounded),
    _FilterChipData(label: 'Co-ed', icon: Icons.people_rounded),
    _FilterChipData(label: 'Under ₹7k', icon: Icons.currency_rupee_rounded),
    _FilterChipData(label: 'AC', icon: Icons.ac_unit_rounded),
    _FilterChipData(label: 'Meals Included', icon: Icons.restaurant_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filters.length,
          itemBuilder: (context, index) {
            final f = _filters[index];
            final isActive = activeFilter == f.label;
            return Padding(
              padding: EdgeInsets.only(
                right: index < _filters.length - 1 ? 8 : 0,
              ),
              child: GestureDetector(
                onTap: () => onFilterChanged(f.label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primaryBrand
                        : AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? AppTheme.primaryBrand
                          : AppTheme.outline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        f.icon,
                        size: 13,
                        color: isActive
                            ? Colors.white
                            : AppTheme.onSurfaceMedium,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        f.label,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isActive
                              ? Colors.white
                              : AppTheme.onSurfaceMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FilterChipData {
  final String label;
  final IconData icon;
  const _FilterChipData({required this.label, required this.icon});
}
