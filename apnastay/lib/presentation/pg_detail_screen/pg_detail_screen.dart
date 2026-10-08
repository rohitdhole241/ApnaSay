import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import '../../widgets/pg_video_player.dart';
import '../pg_listings_screen/pg_listings_screen.dart';

class PgDetailScreen extends StatefulWidget {
  const PgDetailScreen({super.key});

  @override
  State<PgDetailScreen> createState() => _PgDetailScreenState();
}

class _PgDetailScreenState extends State<PgDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool _isSaved = false;

  // Legacy fallback data retained for compatibility; the UI uses live listing data.
  // ignore: unused_field
  static const List<Map<String, dynamic>> _amenities = [
    {'icon': Icons.wifi_rounded, 'label': 'High-Speed WiFi', 'available': true},
    {
      'icon': Icons.ac_unit_rounded,
      'label': 'Air Conditioning',
      'available': true,
    },
    {
      'icon': Icons.restaurant_rounded,
      'label': 'Meals Included',
      'available': true,
    },
    {
      'icon': Icons.local_laundry_service_rounded,
      'label': 'Laundry',
      'available': true,
    },
    {
      'icon': Icons.security_rounded,
      'label': '24/7 Security',
      'available': true,
    },
    {
      'icon': Icons.fitness_center_rounded,
      'label': 'Gym Access',
      'available': true,
    },
    {
      'icon': Icons.local_parking_rounded,
      'label': 'Parking',
      'available': false,
    },
    {'icon': Icons.power_rounded, 'label': 'Power Backup', 'available': true},
    {'icon': Icons.water_drop_rounded, 'label': 'Hot Water', 'available': true},
    {'icon': Icons.tv_rounded, 'label': 'TV Lounge', 'available': false},
    {
      'icon': Icons.cleaning_services_rounded,
      'label': 'Housekeeping',
      'available': true,
    },
    {'icon': Icons.elevator_rounded, 'label': 'Lift', 'available': true},
  ];

  // ignore: unused_field
  static const List<Map<String, dynamic>> _rentBreakdown = [
    {'label': 'Base Rent', 'amount': '8,500', 'isTotal': false},
    {'label': 'Electricity (avg)', 'amount': '600', 'isTotal': false},
    {'label': 'Water Charges', 'amount': '150', 'isTotal': false},
    {'label': 'Maintenance', 'amount': '250', 'isTotal': false},
    {'label': 'Total Monthly', 'amount': '9,500', 'isTotal': true},
  ];

  // ignore: unused_field
  static const List<Map<String, String>> _rules = [
    {'icon': '🕙', 'text': 'Gate closes at 10:00 PM'},
    {'icon': '🚭', 'text': 'No smoking on premises'},
    {'icon': '🍺', 'text': 'No alcohol allowed'},
    {'icon': '👥', 'text': 'No overnight guests'},
    {'icon': '🐾', 'text': 'No pets allowed'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  IconData _amenityIcon(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('wi-fi') || normalized.contains('wifi')) {
      return Icons.wifi_rounded;
    }
    if (normalized.contains('food') || normalized.contains('meal')) {
      return Icons.restaurant_rounded;
    }
    if (normalized.contains('laundry')) {
      return Icons.local_laundry_service_rounded;
    }
    if (normalized.contains('parking')) return Icons.local_parking_rounded;
    if (normalized.contains('cctv') || normalized.contains('security')) {
      return Icons.security_rounded;
    }
    if (normalized.contains('power')) return Icons.power_rounded;
    if (normalized.contains('housekeeping')) {
      return Icons.cleaning_services_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }

  void _showBookingSheet(BuildContext context, PgModel pg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingBottomSheet(pg: pg),
    );
  }

  void _showImageViewer(String url, String label) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (dialogContext) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(label),
            leading: IconButton(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white70,
                    size: 56,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showVideoTour(String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: PgVideoPlayer(url: url),
          ),
        ),
      ),
    );
  }

  void _showContactSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContactOwnerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pg = ModalRoute.of(context)?.settings.arguments as PgModel?;

    final String pgName = pg?.name ?? 'Green Nest PG';
    final String pgLocality = pg?.locality ?? 'Andheri West';
    final String pgCity = pg?.city ?? 'Mumbai';
    final String pgPrice = pg?.price ?? '8,500';
    final String pgRoomType = pg?.roomType ?? 'Single';
    final String pgGender = pg?.gender ?? 'Girls';
    final double pgRating = pg?.rating ?? 4.7;
    final int pgReviewCount = pg?.reviewCount ?? 38;
    final bool pgIsVerified = pg?.isVerified ?? true;
    final String pgDistance = pg?.distance ?? '1.2 km';
    final bool pgIsAvailable = pg?.isAvailable ?? true;
    final ownerName = pg?.ownerName ?? 'PG Owner';
    final ownerPhotoUrl = pg?.ownerPhotoUrl.trim() ?? '';
    final videoUrls = pg?.videoUrls ?? <String>[];
    final ownerInitials = ownerName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .take(2)
        .join()
        .toUpperCase();
    final carouselImages = (pg?.imageUrls ?? []).isNotEmpty
        ? pg!.imageUrls
              .map(
                (url) => <String, String>{'url': url, 'label': '$pgName photo'},
              )
              .toList()
        : <Map<String, String>>[
            {'url': '', 'label': '$pgName photo'},
          ];
    final detailAmenities = (pg?.amenities ?? [])
        .map(
          (label) => <String, dynamic>{
            'icon': _amenityIcon(label),
            'label': label,
            'available': true,
          },
        )
        .toList();
    final rentBreakdown = <Map<String, dynamic>>[
      {'label': 'Base Rent', 'amount': pgPrice, 'isTotal': false},
      {'label': 'Total Monthly', 'amount': pgPrice, 'isTotal': true},
    ];
    const ruleLabels = {
      'visitor_policy': 'Visitor policy',
      'entry_exit_timing': 'Entry and exit timing',
      'smoking_alcohol_policy': 'Smoking/alcohol policy',
      'notice_period': 'Notice period',
    };
    final detailRules = (pg?.rules ?? {}).entries
        .where(
          (entry) =>
              entry.value.trim().isNotEmpty &&
              entry.value.trim().toLowerCase() != 'none',
        )
        .map(
          (entry) => <String, String>{
            'icon': '•',
            'text': '${ruleLabels[entry.key] ?? entry.key}: ${entry.value}',
          },
        )
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Image Carousel SliverAppBar ─────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: AppTheme.surface,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(120),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: () => setState(() => _isSaved = !_isSaved),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(120),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: _isSaved
                            ? const Color(0xFFFFC107)
                            : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      margin: const EdgeInsets.only(
                        right: 12,
                        top: 8,
                        bottom: 8,
                      ),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(120),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
                expandedHeight: MediaQuery.of(context).size.width >= 900
                    ? 520
                    : 300,
                flexibleSpace: FlexibleSpaceBar(
                  background: Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width > 1360
                          ? 1360
                          : MediaQuery.of(context).size.width,
                      child: Stack(
                        children: [
                          // Carousel
                          PageView.builder(
                            controller: _pageController,
                            itemCount: carouselImages.length,
                            onPageChanged: (i) =>
                                setState(() => _currentImageIndex = i),
                            itemBuilder: (context, index) {
                              final imageUrl = carouselImages[index]['url']!;
                              final imageLabel =
                                  carouselImages[index]['label']!;
                              return GestureDetector(
                                onTap: imageUrl.trim().isEmpty
                                    ? null
                                    : () => _showImageViewer(
                                        imageUrl,
                                        imageLabel,
                                      ),
                                child: Container(
                                  width: double.infinity,
                                  height:
                                      MediaQuery.of(context).size.width >= 900
                                      ? 520
                                      : 300,
                                  color: const Color(0xFF24211E),
                                  alignment: Alignment.center,
                                  child: CustomImageWidget(
                                    imageUrl: imageUrl,
                                    width: double.infinity,
                                    height:
                                        MediaQuery.of(context).size.width >= 900
                                        ? 520
                                        : 300,
                                    fit: BoxFit.contain,
                                    semanticLabel: imageLabel,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Dark gradient at bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 80,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withAlpha(160),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Dot indicators
                          Positioned(
                            bottom: 14,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                carouselImages.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  width: _currentImageIndex == i ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == i
                                        ? Colors.white
                                        : Colors.white.withAlpha(120),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Image counter
                          Positioned(
                            bottom: 14,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(140),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_currentImageIndex + 1}/${carouselImages.length}',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // Availability badge
                          Positioned(
                            top: 60,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: pgIsAvailable
                                    ? AppTheme.primaryBrand
                                    : const Color(0xFFB91C1C),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                pgIsAvailable ? '✓ Available' : 'Occupied',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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

              // ── Body Content ────────────────────────────────
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (videoUrls.isNotEmpty)
                          Container(
                            color: AppTheme.surface,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.video_library_outlined,
                                  color: AppTheme.primaryBrand,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${videoUrls.length} PG video tour${videoUrls.length == 1 ? '' : 's'}',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _showVideoTour(videoUrls.first),
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Play'),
                                ),
                              ],
                            ),
                          ),
                        // ── Header Card ──────────────────────────
                        Container(
                          color: AppTheme.surface,
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Verified badge + gender tag row
                              Row(
                                children: [
                                  if (pgIsVerified) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F0FF),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF1565C0,
                                          ).withAlpha(60),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.verified_rounded,
                                            size: 14,
                                            color: Color(0xFF1565C0),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            'ApnaStay Verified',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1565C0),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBrandLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      pgGender,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryBrand,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Rating
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 16,
                                        color: Color(0xFFFFC107),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '$pgRating',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        ' ($pgReviewCount reviews)',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: AppTheme.onSurfaceMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // PG Name
                              Text(
                                pgName,
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Location
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 16,
                                    color: AppTheme.onSurfaceMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$pgLocality, $pgCity',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: AppTheme.onSurfaceMedium,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.directions_walk_rounded,
                                    size: 16,
                                    color: AppTheme.onSurfaceMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    pgDistance,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: AppTheme.onSurfaceMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Price + Room type
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Starting from',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: AppTheme.onSurfaceMuted,
                                        ),
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            '₹$pgPrice',
                                            style: GoogleFonts.outfit(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.primaryBrand,
                                            ),
                                          ),
                                          Text(
                                            '/month',
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              color: AppTheme.onSurfaceMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppTheme.outline,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Room Type',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            color: AppTheme.onSurfaceMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          pgRoomType,
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── Rent Breakdown ───────────────────────
                        Container(
                          color: AppTheme.surface,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                title: 'Rent Breakdown',
                                icon: Icons.receipt_long_rounded,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.outline),
                                ),
                                child: Column(
                                  children: List.generate(
                                    rentBreakdown.length,
                                    (i) {
                                      final item = rentBreakdown[i];
                                      final isTotal = item['isTotal'] as bool;
                                      final isLast =
                                          i == rentBreakdown.length - 1;
                                      return Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isTotal
                                                  ? AppTheme.primaryBrandLight
                                                  : Colors.transparent,
                                              borderRadius: isLast
                                                  ? const BorderRadius.vertical(
                                                      bottom: Radius.circular(
                                                        12,
                                                      ),
                                                    )
                                                  : BorderRadius.zero,
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  item['label'] as String,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: isTotal ? 14 : 13,
                                                    fontWeight: isTotal
                                                        ? FontWeight.w700
                                                        : FontWeight.w400,
                                                    color: isTotal
                                                        ? AppTheme.primaryBrand
                                                        : AppTheme
                                                              .onSurfaceMedium,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  '₹${item['amount']}',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: isTotal ? 16 : 13,
                                                    fontWeight: isTotal
                                                        ? FontWeight.w800
                                                        : FontWeight.w500,
                                                    color: isTotal
                                                        ? AppTheme.primaryBrand
                                                        : AppTheme.onSurface,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!isLast)
                                            const Divider(
                                              height: 1,
                                              color: AppTheme.outline,
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 14,
                                    color: AppTheme.onSurfaceMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Security deposit: ₹${pg?.securityDeposit ?? '-'}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: AppTheme.onSurfaceMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── Amenities Grid ───────────────────────
                        Container(
                          color: AppTheme.surface,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                title: 'Amenities',
                                icon: Icons.checklist_rounded,
                              ),
                              const SizedBox(height: 14),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 1.1,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                itemCount: detailAmenities.length,
                                itemBuilder: (context, index) {
                                  final amenity = detailAmenities[index];
                                  final available =
                                      amenity['available'] as bool;
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: available
                                          ? AppTheme.primaryBrandLight
                                          : AppTheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: available
                                            ? AppTheme.primaryBrand.withAlpha(
                                                60,
                                              )
                                            : AppTheme.outline,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          amenity['icon'] as IconData,
                                          size: 24,
                                          color: available
                                              ? AppTheme.primaryBrand
                                              : AppTheme.onSurfaceMuted,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          amenity['label'] as String,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: available
                                                ? AppTheme.onSurface
                                                : AppTheme.onSurfaceMuted,
                                          ),
                                        ),
                                        if (!available)
                                          Text(
                                            'Not available',
                                            style: GoogleFonts.outfit(
                                              fontSize: 9,
                                              color: AppTheme.onSurfaceMuted,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── About / Description ──────────────────
                        Container(
                          color: AppTheme.surface,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                title: 'About this PG',
                                icon: Icons.info_rounded,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                pg?.address.isNotEmpty == true
                                    ? pg!.address
                                    : 'Located in $pgLocality, $pgCity. Contact the owner for more details about this property.',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: AppTheme.onSurfaceMedium,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Quick facts row
                              Row(
                                children: [
                                  _QuickFact(
                                    icon: Icons.home_rounded,
                                    label: 'Total Rooms',
                                    value: pg?.availableBeds ?? '-',
                                  ),
                                  const SizedBox(width: 12),
                                  _QuickFact(
                                    icon: Icons.people_rounded,
                                    label: 'Occupancy',
                                    value: pg?.availableFrom ?? '-',
                                  ),
                                  const SizedBox(width: 12),
                                  _QuickFact(
                                    icon: Icons.calendar_today_rounded,
                                    label: 'Est.',
                                    value: pg?.roomType ?? '-',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── House Rules ──────────────────────────
                        Container(
                          color: AppTheme.surface,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                title: 'House Rules',
                                icon: Icons.rule_rounded,
                              ),
                              const SizedBox(height: 12),
                              ...detailRules.map(
                                (rule) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Text(
                                        rule['icon']!,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        rule['text']!,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: AppTheme.onSurfaceMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── Owner Info ───────────────────────────
                        Container(
                          color: AppTheme.surface,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                title: 'Property Owner',
                                icon: Icons.person_rounded,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: AppTheme.primaryBrandLight,
                                    backgroundImage: ownerPhotoUrl.isEmpty
                                        ? null
                                        : CachedNetworkImageProvider(
                                            ownerPhotoUrl,
                                          ),
                                    child: ownerPhotoUrl.isEmpty
                                        ? Text(
                                            ownerInitials.isEmpty
                                                ? 'PO'
                                                : ownerInitials,
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.primaryBrand,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              ownerName,
                                              style: GoogleFonts.outfit(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.verified_rounded,
                                              size: 16,
                                              color: Color(0xFF1565C0),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'PG Owner · Registered on ApnaStay',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: AppTheme.onSurfaceMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              size: 13,
                                              color: Color(0xFFFFC107),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '$pgRating · $pgReviewCount reviews',
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                color: AppTheme.onSurfaceMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBrandLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Responds\nquickly',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryBrand,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Bottom padding for CTA bar
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Sticky CTA Bar ───────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Row(
                    children: [
                      // Contact Owner
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showContactSheet(context),
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 18,
                          ),
                          label: const Text('Contact Owner'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryBrand,
                            side: const BorderSide(
                              color: AppTheme.primaryBrand,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Book Now
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: pg == null || !pgIsAvailable
                              ? null
                              : () => _showBookingSheet(context, pg),
                          icon: const Icon(
                            Icons.calendar_month_rounded,
                            size: 18,
                          ),
                          label: const Text('Book Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBrand,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}

// ── Section Header Helper ──────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryBrandLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppTheme.primaryBrand),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ── Quick Fact Chip ────────────────────────────────────────────
class _QuickFact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuickFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryBrand),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Booking Bottom Sheet ───────────────────────────────────────
class _BookingBottomSheet extends StatefulWidget {
  final PgModel pg;

  const _BookingBottomSheet({required this.pg});

  @override
  State<_BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<_BookingBottomSheet> {
  String _selectedDuration = '1 Month';
  final List<String> _durations = [
    '1 Month',
    '3 Months',
    '6 Months',
    '12 Months',
  ];
  bool _isSubmitting = false;

  Future<void> _submitBooking() async {
    setState(() => _isSubmitting = true);
    try {
      await AuthService().createBooking(
        pgId: widget.pg.id,
        amount: double.tryParse(widget.pg.price.replaceAll(',', '')) ?? 0,
        duration: _selectedDuration,
        roomType: widget.pg.roomType,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Booking request sent to the PG owner.')),
      );
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send the request: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Book Your Stay',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select your preferred duration',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _durations.map((d) {
              final selected = _selectedDuration == d;
              return GestureDetector(
                onTap: () => setState(() => _selectedDuration = d),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primaryBrand
                        : AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? AppTheme.primaryBrand
                          : AppTheme.outline,
                    ),
                  ),
                  child: Text(
                    d,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppTheme.onSurfaceMedium,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrandLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppTheme.primaryBrand,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Move-in date can be selected after booking confirmation.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.primaryBrand,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBrand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirm Booking · $_selectedDuration',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contact Owner Bottom Sheet ─────────────────────────────────
class _ContactOwnerSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryBrandLight,
                child: Text(
                  'RK',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBrand,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rajesh Kumar',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    'Typically replies within 1 hour',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ContactOption(
            icon: Icons.phone_rounded,
            label: 'Call Owner',
            subtitle: '+91 98765 XXXXX',
            color: AppTheme.primaryBrand,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 10),
          _ContactOption(
            icon: Icons.chat_rounded,
            label: 'Chat on WhatsApp',
            subtitle: 'Open WhatsApp',
            color: const Color(0xFF25D366),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 10),
          _ContactOption(
            icon: Icons.message_rounded,
            label: 'Send Message',
            subtitle: 'In-app message',
            color: AppTheme.secondaryBrand,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _ContactOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ContactOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
