import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';

class FeatureCardsRowWidget extends StatelessWidget {
  final bool vertical;

  const FeatureCardsRowWidget({super.key, this.vertical = false});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _FeatureCard(
        title: 'Find PG',
        subtitle: '2,400+ verified listings',
        icon: Icons.house_rounded,
        color: AppTheme.primaryBrand,
        bgColor: AppTheme.primaryBrandLight,
        accentColor: const Color(0xFF1A4D2B),
        route: AppRoutes.pgListingsScreen,
        tag: 'New Areas',
        tagColor: AppTheme.primaryBrand,
      ),
      _FeatureCard(
        title: 'Roommates',
        subtitle: '87% avg compatibility',
        icon: Icons.people_rounded,
        color: AppTheme.secondaryBrand,
        bgColor: AppTheme.secondaryBrandLight,
        accentColor: const Color(0xFF2A5A6A),
        route: AppRoutes.roommateMatchingScreen,
        tag: '14 Matches',
        tagColor: AppTheme.secondaryBrand,
      ),
      _FeatureCard(
        title: 'Order Dabba',
        subtitle: 'Home-cooked from ₹80/meal',
        icon: Icons.lunch_dining_rounded,
        color: AppTheme.tertiaryBrand,
        bgColor: AppTheme.tertiaryBrandLight,
        accentColor: const Color(0xFF8B3A18),
        route: AppRoutes.dabbaServiceScreen,
        tag: "Today's Menu",
        tagColor: AppTheme.tertiaryBrand,
      ),
    ];

    if (vertical) {
      return Column(
        children: cards.map((c) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FeatureCardWidget(card: c),
          );
        }).toList(),
      );
    }

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cards.length,
        itemBuilder: (context, i) {
          return Padding(
            padding: EdgeInsets.only(right: i < cards.length - 1 ? 12 : 0),
            child: SizedBox(
              width: 150,
              child: _FeatureCardWidget(card: cards[i]),
            ),
          );
        },
      ),
    );
  }
}

class _FeatureCardWidget extends StatefulWidget {
  final _FeatureCard card;

  const _FeatureCardWidget({required this.card});

  @override
  State<_FeatureCardWidget> createState() => _FeatureCardWidgetState();
}

class _FeatureCardWidgetState extends State<_FeatureCardWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.card;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => Navigator.pushNamed(context, c.route),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.color.withAlpha(38)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c.color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(c.icon, size: 18, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.color.withAlpha(31),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      c.tag,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: c.tagColor,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.accentColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: c.color.withAlpha(191),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color accentColor;
  final String route;
  final String tag;
  final Color tagColor;

  _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.accentColor,
    required this.route,
    required this.tag,
    required this.tagColor,
  });
}
