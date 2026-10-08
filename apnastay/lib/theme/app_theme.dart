import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
 // ── Brand Colors ──────────────────────────────────────────────
static const Color primaryBrand = Color(0xFFE07B39);       
static const Color primaryBrandLight = Color(0xFFFDF0E6);
static const Color primaryBrandMuted = Color(0x26E07B39);
static const Color secondaryBrand = Color(0xFF1A6B72);     
static const Color secondaryBrandLight = Color(0xFFE6F4F5);
static const Color secondaryBrandMuted = Color(0x261A6B72);
static const Color tertiaryBrand = Color(0xFFD4A017);      
static const Color tertiaryBrandLight = Color(0xFFFDF8E1);
static const Color tertiaryBrandMuted = Color(0x26D4A017);

// ── Semantic Colors ───────────────────────────────────────────
static const Color success = Color(0xFF1A6B72);
static const Color warning = Color(0xFFD4A017);
static const Color error = Color(0xFFB91C1C);
static const Color info = Color(0xFF1A6B72);

// ── Neutral Scale ─────────────────────────────────────────────
static const Color background = Color(0xFFFAF7F2);       
static const Color surface = Color(0xFFFFFFFF);
static const Color surfaceVariant = Color(0xFFF5EFE6);     
static const Color outline = Color(0xFFE8DDD0);
static const Color outlineVariant = Color(0xFFF0EAE0);
static const Color onSurface = Color(0xFF1A1A1A);
static const Color onSurfaceMedium = Color(0xFF555555);
static const Color onSurfaceMuted = Color(0xFF9E9E9E);

// ── Verified Badge ────────────────────────────────────────────
static const Color verifiedBadge = Color(0xFF1A6B72);      
static const Color verifiedBadgeLight = Color(0xFFE6F4F5);

  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primaryBrand,
        onPrimary: Colors.white,
        primaryContainer: primaryBrandLight,
        onPrimaryContainer: primaryBrand,
        secondary: secondaryBrand,
        onSecondary: Colors.white,
        secondaryContainer: secondaryBrandLight,
        onSecondaryContainer: secondaryBrand,
        tertiary: tertiaryBrand,
        onTertiary: Colors.white,
        tertiaryContainer: tertiaryBrandLight,
        onTertiaryContainer: tertiaryBrand,
        error: error,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        displaySmall: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        titleSmall: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: onSurfaceMedium,
        ),
        bodySmall: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: onSurfaceMuted,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        labelMedium: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: onSurfaceMedium,
        ),
        labelSmall: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: onSurfaceMuted,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: onSurface),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBrand, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: onSurfaceMuted,
        ),
        hintStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: onSurfaceMuted,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBrand,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBrand,
          side: const BorderSide(color: primaryBrand, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primaryBrandLight,
        labelStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: onSurfaceMedium,
        ),
        side: const BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: onSurface,
        contentTextStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF111714),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF5DBF7A),
        onPrimary: Color(0xFF003914),
        primaryContainer: Color(0xFF1A4D2B),
        secondary: Color(0xFF72B3C5),
        onSecondary: Color(0xFF003543),
        tertiary: Color(0xFFFF8A5C),
        onTertiary: Color(0xFF4A1800),
        error: Color(0xFFFF6B6B),
        surface: Color(0xFF1C2120),
        onSurface: Color(0xFFE8EDE9),
        surfaceContainerHighest: Color(0xFF2A312E),
        outline: Color(0xFF3D4740),
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme),
    );
  }
}
