import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class HomeAppBarWidget extends StatefulWidget {
  final bool isSearchActive;
  final VoidCallback onSearchToggle;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;
  final String userName;
  final String userPhotoUrl;
  final int notificationCount;

  const HomeAppBarWidget({
    super.key,
    required this.isSearchActive,
    required this.onSearchToggle,
    required this.onProfileTap,
    required this.onNotificationTap,
    required this.userName,
    required this.userPhotoUrl,
    required this.notificationCount,
  });

  @override
  State<HomeAppBarWidget> createState() => _HomeAppBarWidgetState();
}

class _HomeAppBarWidgetState extends State<HomeAppBarWidget> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void didUpdateWidget(HomeAppBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSearchActive && !oldWidget.isSearchActive) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _initials() {
    final parts = widget.userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length.clamp(1, 2))
          .toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildInitialsAvatar() => Center(
    child: Text(
      _initials(),
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.primaryBrand,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: widget.isSearchActive ? _buildSearchBar() : _buildTitleBar(),
      ),
    );
  }

  Widget _buildTitleBar() {
    return Row(
      key: const ValueKey('title'),
      children: [
        // Greeting column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'Mumbai',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppTheme.onSurfaceMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Search icon
        GestureDetector(
          onTap: widget.onSearchToggle,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 20,
              color: AppTheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Roommate request inbox
        Tooltip(
          message: 'Notifications',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onNotificationTap,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        size: 20,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    if (widget.notificationCount > 0)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 17,
                            minHeight: 17,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            widget.notificationCount > 9
                                ? '9+'
                                : '${widget.notificationCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Avatar
        GestureDetector(
          onTap: widget.onProfileTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryBrandLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.userPhotoUrl.trim().isEmpty
                  ? _buildInitialsAvatar()
                  : CachedNetworkImage(
                      imageUrl: widget.userPhotoUrl.trim(),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _buildInitialsAvatar(),
                      errorWidget: (_, __, ___) => _buildInitialsAvatar(),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      key: const ValueKey('search'),
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryBrand, width: 1.5),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: AppTheme.primaryBrand,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppTheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by city, locality...',
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.onSurfaceMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            _searchController.clear();
            widget.onSearchToggle();
          },
          child: Text(
            'Cancel',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryBrand,
            ),
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }
}
