import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../routes/app_routes.dart';
import '../pg_listings_screen.dart';

class PgCardWidget extends StatefulWidget {
  final PgModel pg;

  const PgCardWidget({super.key, required this.pg});

  @override
  State<PgCardWidget> createState() => _PgCardWidgetState();
}

class _PgCardWidgetState extends State<PgCardWidget> {
  final bool _isExpanded = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final pg = widget.pg;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.pgDetailScreen, arguments: pg);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: _isExpanded
                ? Border.all(
                    color: AppTheme.primaryBrand.withAlpha(77),
                    width: 1.5,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image section ─────────────────────────────
                Stack(
                  children: [
                    CustomImageWidget(
                      imageUrl: pg.imageUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      semanticLabel: pg.semanticLabel,
                    ),
                    // Gradient overlay at bottom of image
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withAlpha(115),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Verified badge
                    if (pg.isVerified)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1565C0).withAlpha(89),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 11,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ApnaStay Verified',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Availability badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: pg.isAvailable
                              ? AppTheme.primaryBrand
                              : const Color(0xFFB91C1C),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pg.isAvailable ? 'Available' : 'Occupied',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Rating overlay on image bottom-right
                    Positioned(
                      bottom: 8,
                      right: 10,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: Color(0xFFFFC107),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${pg.rating}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFeatures: [
                                const FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            ' (${pg.reviewCount})',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Room type bottom-left
                    Positioned(
                      bottom: 8,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(140),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          pg.roomType,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Content section ───────────────────────────
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price + gender row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '₹${pg.price}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primaryBrand,
                                        fontFeatures: [
                                          const FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '/month',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: AppTheme.onSurfaceMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _GenderBadge(gender: pg.gender),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Name
                      Text(
                        pg.name,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Locality + distance
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: AppTheme.onSurfaceMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            pg.locality,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppTheme.onSurfaceMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: AppTheme.onSurfaceMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.directions_walk_rounded,
                            size: 13,
                            color: AppTheme.secondaryBrand,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            pg.distance,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.secondaryBrand,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Amenities chips
                      _AmenitiesRow(amenities: pg.amenities),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppTheme.primaryBrandLight,
                            backgroundImage: pg.ownerPhotoUrl.isEmpty
                                ? null
                                : CachedNetworkImageProvider(pg.ownerPhotoUrl),
                            child: pg.ownerPhotoUrl.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: AppTheme.primaryBrand,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pg.ownerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurfaceMedium,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.photo_library_outlined,
                            size: 14,
                            color: AppTheme.onSurfaceMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${pg.imageUrls.length}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppTheme.onSurfaceMuted,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.videocam_outlined,
                            size: 15,
                            color: AppTheme.onSurfaceMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${pg.videoUrls.length}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppTheme.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),

                      // ── Expanded section ──────────────────
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutQuart,
                        height: _isExpanded ? 130 : 0,
                        child: ClipRect(
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                Container(
                                  height: 1,
                                  color: AppTheme.outlineVariant,
                                ),
                                const SizedBox(height: 12),
                                // Posted + extra info row
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 13,
                                      color: AppTheme.onSurfaceMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Posted ${pg.postedAgo}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: AppTheme.onSurfaceMuted,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.people_outline_rounded,
                                      size: 13,
                                      color: AppTheme.onSurfaceMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      pg.gender,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: AppTheme.onSurfaceMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Action buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            AppRoutes.pgDetailScreen,
                                            arguments: pg,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.phone_outlined,
                                          size: 15,
                                        ),
                                        label: Text(
                                          'Contact Owner',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              AppTheme.primaryBrand,
                                          side: const BorderSide(
                                            color: AppTheme.primaryBrand,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: pg.isAvailable
                                            ? () {
                                                Navigator.pushNamed(
                                                  context,
                                                  AppRoutes.pgDetailScreen,
                                                  arguments: pg,
                                                );
                                              }
                                            : null,
                                        icon: const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 15,
                                        ),
                                        label: Text(
                                          pg.isAvailable
                                              ? 'Book Now'
                                              : 'Waitlist',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: pg.isAvailable
                                              ? AppTheme.primaryBrand
                                              : AppTheme.onSurfaceMuted,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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
                      ),

                      // Expand indicator
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: AppTheme.onSurfaceMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderBadge extends StatelessWidget {
  final String gender;

  const _GenderBadge({required this.gender});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    IconData icon;

    switch (gender) {
      case 'Girls':
        color = AppTheme.tertiaryBrand;
        bg = AppTheme.tertiaryBrandLight;
        icon = Icons.female_rounded;
        break;
      case 'Boys':
        color = AppTheme.secondaryBrand;
        bg = AppTheme.secondaryBrandLight;
        icon = Icons.male_rounded;
        break;
      default:
        color = AppTheme.primaryBrand;
        bg = AppTheme.primaryBrandLight;
        icon = Icons.people_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(
            gender,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenitiesRow extends StatelessWidget {
  final List<String> amenities;

  const _AmenitiesRow({required this.amenities});

  static const Map<String, IconData> _amenityIcons = {
    'WiFi': Icons.wifi_rounded,
    'AC': Icons.ac_unit_rounded,
    'Meals': Icons.restaurant_rounded,
    'Laundry': Icons.local_laundry_service_rounded,
    'Parking': Icons.local_parking_rounded,
    'Gym': Icons.fitness_center_rounded,
    'Security': Icons.security_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final visible = amenities.take(4).toList();
    final extra = amenities.length - visible.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...visible.map(
          (a) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: AppTheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _amenityIcons[a] ?? Icons.check_circle_outline_rounded,
                  size: 12,
                  color: AppTheme.onSurfaceMedium,
                ),
                const SizedBox(width: 4),
                Text(
                  a,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurfaceMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (extra > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrandLight,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '+$extra more',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBrand,
              ),
            ),
          ),
      ],
    );
  }
}
