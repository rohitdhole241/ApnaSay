import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class GoogleAuthButtonWidget extends StatefulWidget {
  const GoogleAuthButtonWidget({super.key});

  @override
  State<GoogleAuthButtonWidget> createState() => _GoogleAuthButtonWidgetState();
}

class _GoogleAuthButtonWidgetState extends State<GoogleAuthButtonWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        // TODO: Implement Google Sign-In for production
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: CustomPaint(painter: _GoogleLogoPainter()),
              ),
              const SizedBox(width: 12),
              Text(
                'Continue with Google',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFFEA4335),
      const Color(0xFFFBBC05),
      const Color(0xFF34A853),
    ];
    final angles = [0.0, 90.0, 180.0, 270.0];
    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        (angles[i] - 5) * 3.14159 / 180,
        90 * 3.14159 / 180,
        true,
        paint,
      );
    }
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(c, r * 0.55, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
