import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class PgListingsAppBarWidget extends StatefulWidget {
  final bool isSearchActive;
  final VoidCallback onSearchToggle;
  final VoidCallback onBack;

  const PgListingsAppBarWidget({
    super.key,
    required this.isSearchActive,
    required this.onSearchToggle,
    required this.onBack,
  });

  @override
  State<PgListingsAppBarWidget> createState() => _PgListingsAppBarWidgetState();
}

class _PgListingsAppBarWidgetState extends State<PgListingsAppBarWidget> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void didUpdateWidget(PgListingsAppBarWidget oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: widget.isSearchActive ? _buildSearchBar() : _buildTitleBar(),
      ),
    );
  }

  Widget _buildTitleBar() {
    return Row(
      key: const ValueKey('title'),
      children: [
        if (Navigator.canPop(context)) ...[
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PG Listings',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              Text(
                'Mumbai • 2,400+ options',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
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
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.tune_rounded,
            size: 20,
            color: AppTheme.onSurface,
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
                      hintText: 'Search locality, landmark...',
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
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _searchController.clear()),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppTheme.onSurfaceMuted,
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
}
