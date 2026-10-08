import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AppNavigation extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _snakeAnimation;
  int _prevIndex = 0;

  final List<_NavItem> _items = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: 'Explore',
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Activity',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _snakeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(AppNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _prevIndex = oldWidget.currentIndex;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / _items.length;
              return Stack(
                children: [
                  // Snake indicator
                  AnimatedBuilder(
                    animation: _snakeAnimation,
                    builder: (context, _) {
                      final from = _prevIndex * itemWidth;
                      final to = widget.currentIndex * itemWidth;
                      final current =
                          from + (to - from) * _snakeAnimation.value;
                      return Positioned(
                        left: current + (itemWidth - 64) / 2,
                        top: 8,
                        child: Container(
                          width: 64,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBrand.withAlpha(26),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      );
                    },
                  ),
                  // Nav items
                  Row(
                    children: List.generate(_items.length, (index) {
                      final isActive = index == widget.currentIndex;
                      final item = _items[index];
                      return Expanded(
                        child: InkWell(
                          onTap: () => widget.onTap(index),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                child: Icon(
                                  isActive ? item.activeIcon : item.icon,
                                  key: ValueKey(isActive),
                                  size: 22,
                                  color: isActive
                                      ? AppTheme.primaryBrand
                                      : AppTheme.onSurfaceMuted,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.label,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isActive
                                      ? AppTheme.primaryBrand
                                      : AppTheme.onSurfaceMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  _NavItem({required this.icon, required this.activeIcon, required this.label});
}
