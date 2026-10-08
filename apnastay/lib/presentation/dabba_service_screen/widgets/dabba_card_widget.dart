import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';

class DabbaModel {
  final String id;
  final String providerName;
  final String cuisine;
  final String pricePerMeal;
  final String imageUrl;
  final String providerPhotoUrl;
  final List<String> kitchenPhotoUrls;
  final String semanticLabel;
  final String foodType;
  final List<String> mealCategories;
  final String weeklyPlanPrice;
  final String monthlyPlanPrice;
  final String locality;
  final String city;
  final String deliveryAreas;
  final String deliveryTimings;
  final String deliveryCharges;
  final bool hygieneVerified;
  final List<String> menuPhotoUrls;

  const DabbaModel({
    required this.id,
    required this.providerName,
    required this.cuisine,
    required this.pricePerMeal,
    required this.imageUrl,
    required this.providerPhotoUrl,
    required this.kitchenPhotoUrls,
    required this.semanticLabel,
    required this.foodType,
    required this.mealCategories,
    required this.weeklyPlanPrice,
    required this.monthlyPlanPrice,
    required this.locality,
    required this.city,
    required this.deliveryAreas,
    required this.deliveryTimings,
    required this.deliveryCharges,
    required this.hygieneVerified,
    required this.menuPhotoUrls,
  });

  bool get isVeg =>
      foodType.toLowerCase() == 'vegetarian' ||
      foodType.toLowerCase() == 'jain';
  bool get isNonVeg => foodType.toLowerCase() == 'non-vegetarian';
  bool get isJain => foodType.toLowerCase().contains('jain');
  bool get hasSubscriptionPlans =>
      pricePerMeal.isNotEmpty ||
      weeklyPlanPrice.isNotEmpty ||
      monthlyPlanPrice.isNotEmpty;

  factory DabbaModel.fromMap(Map<String, dynamic> data) {
    String readText(dynamic value, [String fallback = '']) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? fallback : text;
    }

    List<String> readList(dynamic value) => value is Iterable
        ? value
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList()
        : <String>[];

    final name = readText(
      data['provider_name'],
      readText(data['name'], 'Meal provider'),
    );
    final kitchenPhotos = readList(data['kitchen_photo_urls']);
    final profilePhoto = readText(data['provider_photo_url']);

    return DabbaModel(
      id: readText(data['uid']),
      providerName: name,
      cuisine: readText(data['cuisine_type'], 'Cuisine not specified'),
      pricePerMeal: _formatRupees(data['price_per_meal']),
      imageUrl: kitchenPhotos.isNotEmpty ? kitchenPhotos.first : profilePhoto,
      providerPhotoUrl: profilePhoto,
      kitchenPhotoUrls: kitchenPhotos,
      semanticLabel: 'Meal provider $name food and kitchen',
      foodType: readText(data['food_type'], 'Food type not specified'),
      mealCategories: readList(data['meal_categories']),
      weeklyPlanPrice: _formatPlan(data['weekly_plan_price'], 'week'),
      monthlyPlanPrice: _formatPlan(data['monthly_plan_price'], 'month'),
      locality: readText(data['kitchen_locality'], 'Location not specified'),
      city: readText(data['kitchen_city']),
      deliveryAreas: readText(data['delivery_areas']),
      deliveryTimings: readText(data['delivery_timings']),
      deliveryCharges: readText(data['delivery_charges']),
      hygieneVerified: data['hygiene_verified'] == true,
      menuPhotoUrls: readList(data['menu_photo_urls']),
    );
  }
}

String _formatRupees(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return '';

  final numericText = raw
      .replaceAll(',', '')
      .replaceFirst(RegExp(r'^[^\d.-]+'), '');
  final amount = double.tryParse(numericText);
  if (amount == null) return raw;

  final formatted = amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount
            .toStringAsFixed(2)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
  return '\u20B9$formatted';
}

String _formatPlan(dynamic value, String interval) {
  final amount = _formatRupees(value);
  return amount.isEmpty ? '' : '$amount / $interval';
}

class DabbaCardWidget extends StatelessWidget {
  final DabbaModel dabba;
  final VoidCallback onViewDetails;
  final VoidCallback onViewPlans;

  const DabbaCardWidget({
    super.key,
    required this.dabba,
    required this.onViewDetails,
    required this.onViewPlans,
  });

  @override
  Widget build(BuildContext context) {
    final location = [
      dabba.locality,
      dabba.city,
    ].where((part) => part.isNotEmpty).join(', ');
    final heroImageHeight = MediaQuery.sizeOf(context).width >= 1000
        ? 300.0
        : 220.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline.withAlpha(80)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onViewDetails,
              child: SizedBox(
                height: heroImageHeight,
                width: double.infinity,
                child: dabba.imageUrl.isEmpty
                    ? Container(
                        color: AppTheme.tertiaryBrandLight,
                        child: const Icon(
                          Icons.restaurant_rounded,
                          size: 52,
                          color: AppTheme.tertiaryBrand,
                        ),
                      )
                    : CustomImageWidget(
                        imageUrl: dabba.imageUrl,
                        semanticLabel: dabba.semanticLabel,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.tertiaryBrandLight,
                      child: dabba.providerPhotoUrl.isEmpty
                          ? const Icon(
                              Icons.restaurant_rounded,
                              color: AppTheme.tertiaryBrand,
                            )
                          : ClipOval(
                              child: CustomImageWidget(
                                imageUrl: dabba.providerPhotoUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                semanticLabel:
                                    'Meal provider ${dabba.providerName}',
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dabba.providerName,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              location,
                              dabba.cuisine,
                            ].where((part) => part.isNotEmpty).join('  •  '),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppTheme.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          dabba.pricePerMeal.isEmpty
                              ? 'Price not listed'
                              : dabba.pricePerMeal,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.tertiaryBrand,
                          ),
                        ),
                        if (dabba.pricePerMeal.isNotEmpty)
                          Text(
                            'per meal',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppTheme.onSurfaceMuted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (dabba.foodType != 'Food type not specified')
                      _InfoTag(label: dabba.foodType),
                    ...dabba.mealCategories.map((category) {
                      return _InfoTag(label: category);
                    }),
                    if (dabba.hygieneVerified)
                      const _InfoTag(label: 'Hygiene verified'),
                  ],
                ),
                if (dabba.deliveryTimings.isNotEmpty ||
                    dabba.deliveryAreas.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    [
                      if (dabba.deliveryTimings.isNotEmpty)
                        'Delivery: ${dabba.deliveryTimings}',
                      if (dabba.deliveryAreas.isNotEmpty)
                        'Areas: ${dabba.deliveryAreas}',
                    ].join('  |  '),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.onSurfaceMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onViewDetails,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppTheme.tertiaryBrand.withAlpha(120),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'View Details',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.tertiaryBrand,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: dabba.hasSubscriptionPlans
                            ? onViewPlans
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.tertiaryBrand,
                          disabledBackgroundColor: AppTheme.tertiaryBrand
                              .withAlpha(80),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          dabba.hasSubscriptionPlans
                              ? 'Book Service'
                              : 'No plans listed',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
    );
  }
}

class _InfoTag extends StatelessWidget {
  final String label;

  const _InfoTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.tertiaryBrandLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.tertiaryBrand.withAlpha(60)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppTheme.tertiaryBrand,
        ),
      ),
    );
  }
}
