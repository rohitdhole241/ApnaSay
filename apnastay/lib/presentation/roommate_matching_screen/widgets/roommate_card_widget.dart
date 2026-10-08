import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../roommate_matching_screen.dart';

class RoommateCardWidget extends StatefulWidget {
  final RoommateModel roommate;
  final VoidCallback onLike;
  final VoidCallback onPass;
  final VoidCallback? onDetails;
  final bool isTop;

  const RoommateCardWidget({
    super.key,
    required this.roommate,
    required this.onLike,
    required this.onPass,
    this.onDetails,
    this.isTop = false,
  });

  @override
  State<RoommateCardWidget> createState() => _RoommateCardWidgetState();
}

class _RoommateCardWidgetState extends State<RoommateCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isTop) return;
    setState(() {
      _dragOffset += details.delta;
      _dragAngle = _dragOffset.dx * 0.002;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isTop) return;
    const threshold = 100.0;
    if (_dragOffset.dx > threshold) {
      widget.onLike();
    } else if (_dragOffset.dx < -threshold) {
      widget.onPass();
    } else {
      setState(() {
        _dragOffset = Offset.zero;
        _dragAngle = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final roommate = widget.roommate;
    final photoUrl = roommate.imageUrl.trim();
    final location = [roommate.locality, roommate.city]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && value != 'Not specified')
        .toSet()
        .join(' · ');

    return GestureDetector(
      onTap: widget.onDetails,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: _dragAngle,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 260,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (photoUrl.isEmpty)
                            _photoFallback(roommate.name)
                          else
                            ColoredBox(
                              color: AppTheme.secondaryBrandLight,
                              child: Image.network(
                                photoUrl,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) =>
                                    _photoFallback(roommate.name),
                              ),
                            ),
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryBrand,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.favorite_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${roommate.compatibilityScore}% AI match',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${roommate.name}${roommate.age > 0 ? ', ${roommate.age}' : ''}',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 15,
                                  color: AppTheme.onSurfaceMuted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location.isEmpty
                                        ? 'Location not specified'
                                        : location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: AppTheme.onSurfaceMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _infoChip(
                                  Icons.person_outline_rounded,
                                  'Gender',
                                  roommate.gender,
                                ),
                                _infoChip(
                                  Icons.work_outline_rounded,
                                  'Occupation',
                                  roommate.profession,
                                ),
                                _infoChip(
                                  Icons.currency_rupee_rounded,
                                  'Monthly budget',
                                  roommate.budget,
                                ),
                                _infoChip(
                                  Icons.event_outlined,
                                  'Move-in',
                                  roommate.moveInDate,
                                ),
                                _infoChip(
                                  Icons.restaurant_outlined,
                                  'Food preference',
                                  roommate.foodPreference,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              roommate.summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppTheme.onSurfaceMedium,
                                height: 1.4,
                              ),
                            ),
                            if (roommate.matchReasons.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Why this match',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: roommate.matchReasons.take(3).map((reason) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondaryBrandLight,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppTheme.outlineVariant,
                                      ),
                                    ),
                                    child: Text(
                                      reason,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: AppTheme.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            const SizedBox(height: 12),
                            if (roommate.lifestyleTags.isEmpty)
                              Text(
                                'No interests added yet.',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceMuted,
                                ),
                              )
                            else
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: roommate.lifestyleTags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondaryBrandLight,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppTheme.secondaryBrand.withAlpha(
                                          60,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.secondaryBrand,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: widget.onPass,
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: AppTheme.error,
                                    ),
                                    label: Text(
                                      'Pass',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.error,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: AppTheme.error.withAlpha(80),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: widget.onLike,
                                    icon: const Icon(
                                      Icons.favorite_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      'Like',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.secondaryBrand,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_dragOffset.dx > 0)
                  Positioned(
                    top: 40,
                    left: 20,
                    child: _swipeStamp('LIKE', AppTheme.success, _dragOffset.dx),
                  ),
                if (_dragOffset.dx < 0)
                  Positioned(
                    top: 40,
                    right: 20,
                    child: _swipeStamp('NOPE', AppTheme.error, -_dragOffset.dx),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoFallback(String name) => Container(
    color: AppTheme.secondaryBrandLight,
    alignment: Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 42,
          backgroundColor: AppTheme.surface,
          child: Text(
            _initials(name),
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.secondaryBrand,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Profile photo not available',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppTheme.onSurfaceMuted,
          ),
        ),
      ],
    ),
  );

  Widget _infoChip(IconData icon, String label, String value) =>
      ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.secondaryBrand),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: AppTheme.onSurfaceMuted,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _swipeStamp(String label, Color color, double distance) =>
      Transform.rotate(
        angle: label == 'LIKE' ? -0.4 : 0.4,
        child: Opacity(
          opacity: (distance / 100).clamp(0.0, 1.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      );

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length > 1 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
