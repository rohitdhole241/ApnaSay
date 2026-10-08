import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../login_signup_screen.dart';

class RoleSelectorWidget extends StatelessWidget {
  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;

  const RoleSelectorWidget({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final roles = [
      _RoleOption(
        role: UserRole.user,
        label: 'Looking for PG',
        icon: Icons.person_search_rounded,
        color: AppTheme.primaryBrand,
        bgColor: AppTheme.primaryBrandLight,
      ),
      _RoleOption(
        role: UserRole.pgOwner,
        label: 'PG Owner',
        icon: Icons.house_rounded,
        color: AppTheme.secondaryBrand,
        bgColor: AppTheme.secondaryBrandLight,
      ),
      _RoleOption(
        role: UserRole.mealProvider,
        label: 'Meal Provider',
        icon: Icons.restaurant_rounded,
        color: AppTheme.tertiaryBrand,
        bgColor: AppTheme.tertiaryBrandLight,
      ),
    ];

    return Row(
      children: roles.map((r) {
        final isSelected = selectedRole == r.role;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: r.role != UserRole.mealProvider ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => onRoleChanged(r.role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? r.bgColor : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? r.color : AppTheme.outline,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      r.icon,
                      size: 22,
                      color: isSelected ? r.color : AppTheme.onSurfaceMuted,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected ? r.color : AppTheme.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RoleOption {
  final UserRole role;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  _RoleOption({
    required this.role,
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}
