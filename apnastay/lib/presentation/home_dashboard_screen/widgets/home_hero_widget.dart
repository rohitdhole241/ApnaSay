import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../routes/app_routes.dart';

class HomeHeroWidget extends StatelessWidget {
  const HomeHeroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRoutes.pgListingsScreen),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBrand.withAlpha(46),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Hero image
                CustomImageWidget(
                  imageUrl:
                      'https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg',
                  fit: BoxFit.cover,
                  semanticLabel:
                      'Modern furnished PG room with bed, study table and natural light from large window',
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withAlpha(184)],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),
                // Content
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBrand,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '✦  Featured Pick',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Green Nest PG, Andheri West',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.currency_rupee_rounded,
                            size: 14,
                            color: Colors.white70,
                          ),
                          Text(
                            '8,500/mo',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFeatures: [
                                const FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: Colors.white60,
                          ),
                          Text(
                            '1.2 km from you',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'View',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
