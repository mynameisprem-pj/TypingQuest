import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Peaceful Modern Palette ───────────────────────────────────────────────
  // Warm light gray background — not stark white, not dark
  static const Color background   = Color(0xFFF4F6FA);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color card         = Color(0xFFFFFFFF);
  static const Color cardBorder   = Color(0xFFE8EDF5);

  // Soft indigo as primary — calm, focused, modern
  static const Color primary      = Color(0xFF5C7CFA);
  static const Color primaryLight = Color(0xFFEEF1FF);
  static const Color primaryDim   = Color(0xFFB8C6FD);

  // Mint green for success/progress
  static const Color success      = Color(0xFF20C997);
  static const Color successLight = Color(0xFFE6FAF5);

  // Soft coral for errors — not aggressive red
  static const Color error        = Color(0xFFFF6B6B);
  static const Color errorLight   = Color(0xFFFFEEEE);

  // Warm amber for warnings / gold
  static const Color gold         = Color(0xFFFFBE3D);
  static const Color goldLight    = Color(0xFFFFF8E6);

  // Lavender for accents
  static const Color lavender     = Color(0xFFB197FC);
  static const Color lavenderLight = Color(0xFFF3EEFF);

  // Difficulty
  static const Color beginner     = Color(0xFF20C997);
  static const Color intermediate = Color(0xFFFFBE3D);
  static const Color master       = Color(0xFFFF6B6B);

  // Text — warm dark slate, not pure black
  static const Color textPrimary   = Color(0xFF1A1D2E);
  static const Color textSecondary = Color(0xFF6B7BA4);
  static const Color textMuted     = Color(0xFFADB5D0);

  // Finger colors for keyboard (slightly softer)
  static const Color fingerPinky  = Color(0xFFFF8787);
  static const Color fingerRing   = Color(0xFF74C0FC);
  static const Color fingerMiddle = Color(0xFF8CE99A);
  static const Color fingerIndex  = Color(0xFFFFD43B);
  static const Color fingerThumb  = Color(0xFFDA77F2);

  // ── Shadow ────────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: const Color(0xFF5C7CFA).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3)),
  ];

  // ── Text Styles ───────────────────────────────────────────────────────────
  static TextStyle heading(double size, {Color color = textPrimary, FontWeight weight = FontWeight.bold}) {
    return GoogleFonts.poppins(fontSize: size, color: color, fontWeight: weight);
  }

  static TextStyle body(double size, {Color color = textPrimary, FontWeight weight = FontWeight.normal}) {
    return GoogleFonts.inter(fontSize: size, color: color, fontWeight: weight);
  }

  static TextStyle mono(double size, {Color color = textPrimary}) {
    return GoogleFonts.sourceCodePro(fontSize: size, color: color);
  }

  // ── Theme Data ─────────────────────────────────────────────────────────────
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: success,
        surface: surface,
        error: error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
        shadowColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: body(14, color: textSecondary),
        hintStyle: body(14, color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(color: cardBorder, thickness: 1),
      drawerTheme: const DrawerThemeData(backgroundColor: surface),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primary : Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primaryLight : cardBorder),
      ),
    );
  }
}