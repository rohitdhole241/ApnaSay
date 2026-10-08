import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class PgMapPlaceholderWidget extends StatefulWidget {
  const PgMapPlaceholderWidget({super.key});

  @override
  State<PgMapPlaceholderWidget> createState() => _PgMapPlaceholderWidgetState();
}

class _PgMapPlaceholderWidgetState extends State<PgMapPlaceholderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Faux map grid
        CustomPaint(painter: _MapGridPainter(), size: Size.infinite),
        // Map pins
        ..._buildMapPins(),
        // Center overlay card
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) =>
                    Transform.scale(scale: _pulseAnimation.value, child: child),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBrand,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBrand.withAlpha(89),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Map View',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add Google Maps API key to\nenable interactive map view',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.onSurfaceMuted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.outline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryBrand,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '8 PGs in this area',
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
        ),
      ],
    );
  }

  List<Widget> _buildMapPins() {
    final pins = [
      const Offset(0.2, 0.3),
      const Offset(0.6, 0.25),
      const Offset(0.75, 0.55),
      const Offset(0.35, 0.65),
      const Offset(0.15, 0.7),
    ];
    final prices = ['₹8.5k', '₹9.2k', '₹10.5k', '₹6.5k', '₹5.9k'];

    return List.generate(pins.length, (i) {
      return Positioned(
        left: MediaQuery.of(context).size.width * pins[i].dx,
        top: (MediaQuery.of(context).size.height * 0.65) * pins[i].dy,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: i == 0 ? AppTheme.primaryBrand : AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: i == 0 ? AppTheme.primaryBrand : AppTheme.outline,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(31),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            prices[i],
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: i == 0 ? Colors.white : AppTheme.primaryBrand,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ),
      );
    });
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Soft map background
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFF1F6F3),
          const Color(0xFFE4EDE7),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final linePaint = Paint()
      ..color = Colors.white.withAlpha(150)
      ..strokeWidth = 2;

    const spacing = 50.0;
    // Curved/diagonal lines for a modern feel
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), linePaint);
      canvas.drawLine(Offset(i + size.height, 0), Offset(i, size.height), linePaint);
    }

    // Modern blocks
    final blockPaint = Paint()
      ..color = Colors.white.withAlpha(200)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    void drawBlock(Rect rect, double radius) {
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
      canvas.drawRRect(rrect.shift(const Offset(0, 4)), shadowPaint);
      canvas.drawRRect(rrect, blockPaint);
    }

    drawBlock(Rect.fromLTWH(size.width * 0.1, size.height * 0.1, size.width * 0.3, size.height * 0.2), 16);
    drawBlock(Rect.fromLTWH(size.width * 0.6, size.height * 0.15, size.width * 0.3, size.height * 0.3), 16);
    drawBlock(Rect.fromLTWH(size.width * 0.15, size.height * 0.5, size.width * 0.4, size.height * 0.25), 16);
    drawBlock(Rect.fromLTWH(size.width * 0.65, size.height * 0.6, size.width * 0.25, size.height * 0.3), 16);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
