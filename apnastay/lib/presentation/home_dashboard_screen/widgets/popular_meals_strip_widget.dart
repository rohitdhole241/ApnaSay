import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';

class PopularMealsStripWidget extends StatelessWidget {
  const PopularMealsStripWidget({super.key});

  static final List<Map<String, dynamic>> _meals = [
    {
      'provider': 'Anita Aunty Kitchen',
      'cuisine': 'Maharashtrian',
      'price': '90',
      'rating': '4.8',
      'tag': 'Veg',
      'todayMenu': 'Dal Tadka + Roti + Sabzi',
      'imageUrl':
          'https://images.unsplash.com/photo-1515175620159-0634b62d32f8',
      'semanticLabel':
          'Middle-aged Indian woman in yellow saree smiling while cooking dal in traditional kitchen',
      'tagColor': AppTheme.primaryBrand,
      'tagBg': AppTheme.primaryBrandLight,
    },
    {
      'provider': 'Spice Route Tiffin',
      'cuisine': 'South Indian',
      'price': '110',
      'rating': '4.6',
      'tag': 'Veg',
      'todayMenu': 'Sambar Rice + Rasam + Papad',
      'imageUrl':
          'https://images.unsplash.com/photo-1635346025967-994995d961c2',
      'semanticLabel':
          'Colourful South Indian thali with sambar, rasam, rice and multiple small bowls of curries',
      'tagColor': AppTheme.primaryBrand,
      'tagBg': AppTheme.primaryBrandLight,
    },
    {
      'provider': 'Raza Bhai Tiffin',
      'cuisine': 'North Indian',
      'price': '120',
      'rating': '4.5',
      'tag': 'Non-Veg',
      'todayMenu': 'Chicken Curry + Rice + Salad',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_17d57445d-1765978187975.png',
      'semanticLabel':
          'North Indian thali with chicken curry, steamed rice, green salad and pickles in steel plates',
      'tagColor': AppTheme.tertiaryBrand,
      'tagBg': AppTheme.tertiaryBrandLight,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _meals.length,
        itemBuilder: (context, i) {
          final meal = _meals[i];
          return Padding(
            padding: EdgeInsets.only(right: i < _meals.length - 1 ? 12 : 0),
            child: _MealCard(meal: meal),
          );
        },
      ),
    );
  }
}

class _MealCard extends StatefulWidget {
  final Map<String, dynamic> meal;

  const _MealCard({required this.meal});

  @override
  State<_MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<_MealCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.meal;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {},
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with tag overlay
                Stack(
                  children: [
                    CustomImageWidget(
                      imageUrl: m['imageUrl'] as String,
                      width: 200,
                      height: 100,
                      fit: BoxFit.cover,
                      semanticLabel: m['semanticLabel'] as String,
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: m['tagBg'] as Color,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          m['tag'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: m['tagColor'] as Color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              m['provider'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: Color(0xFFFFC107),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                m['rating'] as String,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        m['todayMenu'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppTheme.onSurfaceMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${m['price']}/meal',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.tertiaryBrand,
                              fontFeatures: [
                                const FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.tertiaryBrandLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Subscribe',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.tertiaryBrand,
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
