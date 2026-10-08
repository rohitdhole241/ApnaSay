import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../routes/app_routes.dart';

class NearbyPgStripWidget extends StatelessWidget {
  const NearbyPgStripWidget({super.key});

  static final List<Map<String, dynamic>> _nearbyPgs = [
    {
      'name': 'Sunrise PG',
      'locality': 'Bandra East',
      'price': '9,200',
      'distance': '0.8 km',
      'gender': 'Girls',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1192c674f-1772204102751.png',
      'semanticLabel':
          'Well-lit PG room with white walls, wooden bed and study desk near window',
      'isVerified': true,
      'rating': '4.7',
    },
    {
      'name': 'Comfort Zone PG',
      'locality': 'Powai',
      'price': '7,800',
      'distance': '1.4 km',
      'gender': 'Boys',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1192c674f-1772204102751.png',
      'semanticLabel':
          'Neat PG room with blue accents, single bed and wardrobe with natural lighting',
      'isVerified': true,
      'rating': '4.5',
    },
    {
      'name': 'Urban Nest',
      'locality': 'Malad West',
      'price': '6,500',
      'distance': '2.1 km',
      'gender': 'Co-ed',
      'imageUrl':
          'https://images.unsplash.com/photo-1723470918065-13488200464c',
      'semanticLabel':
          'Modern minimalist room with grey bedding, wooden floors and large window with city view',
      'isVerified': false,
      'rating': '4.2',
    },
    {
      'name': 'HomeAway PG',
      'locality': 'Goregaon',
      'price': '5,900',
      'distance': '3.3 km',
      'gender': 'Girls',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1faeb407c-1775973977580.png',
      'semanticLabel':
          'Cosy furnished PG room with warm lighting, single bed and organised storage space',
      'isVerified': false,
      'rating': '4.0',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _nearbyPgs.length,
        itemBuilder: (context, i) {
          final pg = _nearbyPgs[i];
          return Padding(
            padding: EdgeInsets.only(right: i < _nearbyPgs.length - 1 ? 12 : 0),
            child: _NearbyPgCard(pg: pg),
          );
        },
      ),
    );
  }
}

class _NearbyPgCard extends StatefulWidget {
  final Map<String, dynamic> pg;

  const _NearbyPgCard({required this.pg});

  @override
  State<_NearbyPgCard> createState() => _NearbyPgCardState();
}

class _NearbyPgCardState extends State<_NearbyPgCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final pg = widget.pg;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => Navigator.pushNamed(context, AppRoutes.pgListingsScreen),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 170,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
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
                // Image
                Stack(
                  children: [
                    CustomImageWidget(
                      imageUrl: pg['imageUrl'] as String,
                      width: 170,
                      height: 110,
                      fit: BoxFit.cover,
                      semanticLabel: pg['semanticLabel'] as String,
                    ),
                    if (pg['isVerified'] as bool)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 10,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Verified',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(140),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 10,
                              color: Color(0xFFFFC107),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              pg['rating'] as String,
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
                  ],
                ),
                // Info
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${pg['price']}/mo',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBrand,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pg['name'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 11,
                            color: AppTheme.onSurfaceMuted,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              '${pg['locality']} • ${pg['distance']}',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AppTheme.onSurfaceMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryBrandLight,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          pg['gender'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondaryBrand,
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
