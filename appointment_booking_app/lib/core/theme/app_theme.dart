import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Base Colors
  static const Color primary = Color(0xFF1A1D20);        // Deep Slate
  static const Color primaryAccent = Color(0xFFC49A58);  // Warm Gold / Bronze
  static const Color primaryAccentLight = Color(0xFFD4AF6E); // Illuminated Gold for Dark Mode
  static const Color primaryAccentHover = Color(0xFFB08846);

  // Surface & Background - Light Mode
  static const Color surfaceBackground = Color(0xFFF8F9FA); // Ultra clean off-white
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF111827);    // Charcoal
  static const Color textSecondary = Color(0xFF6B7280);  // Muted grey
  static const Color borderSubtle = Color(0xFFE5E7EB);   // Hairline border

  // Surface & Background - Dark Mode
  static const Color surfaceBackgroundDark = Color(0xFF121417); // Obsidian Slate
  static const Color cardBackgroundDark = Color(0xFF1E2228);    // Elevated Slate
  static const Color textPrimaryDark = Color(0xFFF9FAFB);       // Soft Crisp Ivory
  static const Color textSecondaryDark = Color(0xFF9CA3AF);     // Muted Silver
  static const Color borderSubtleDark = Color(0xFF2D333B);      // Subtle Hairline

  // Status Colors (Vibrant & readable in both modes)
  static const Color statusUpcoming = Color(0xFF0D9488);     // Teal
  static const Color statusUpcomingDark = Color(0xFF14B8A6); // Bright Teal
  static const Color statusPast = Color(0xFF6B7280);         // Neutral Grey
  static const Color statusCancelled = Color(0xFFDC2626);    // Refined Ruby Red
  static const Color statusCancelledDark = Color(0xFFEF4444);// Bright Red

  // Slot States - Light Mode
  static const Color slotAvailable = Colors.white;
  static const Color slotSelected = Color(0xFF1A1D20);
  static const Color slotDisabled = Color(0xFFF3F4F6);

  // Slot States - Dark Mode
  static const Color slotAvailableDark = Color(0xFF1E2228);
  static const Color slotSelectedDark = Color(0xFFC49A58);
  static const Color slotDisabledDark = Color(0xFF16181C);

  // Dynamic Theme Helpers
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? textPrimaryDark : textPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? textSecondaryDark : textSecondary;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? cardBackgroundDark : cardBackground;

  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? surfaceBackgroundDark : surfaceBackground;

  static Color borderOf(BuildContext context) =>
      isDark(context) ? borderSubtleDark : borderSubtle;

  static Color accentOf(BuildContext context) =>
      isDark(context) ? primaryAccentLight : primaryAccent;

  static Color statusUpcomingOf(BuildContext context) =>
      isDark(context) ? statusUpcomingDark : statusUpcoming;

  static Color statusCancelledOf(BuildContext context) =>
      isDark(context) ? statusCancelledDark : statusCancelled;

  static SystemUiOverlayStyle systemOverlayStyleOf(BuildContext context) {
    final dark = isDark(context);
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }

  // --- Light Theme ---
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: surfaceBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryAccent,
        secondary: primaryAccentHover,
        surface: cardBackground,
        error: statusCancelled,
        onPrimary: Color(0xFF121417),
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderSubtle),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: primaryAccent, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: statusCancelled),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: statusCancelled, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
        bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary),
      ),
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 1,
      ),
    );
  }

  // --- Dark Theme ---
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surfaceBackgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryAccentLight,
        secondary: primaryAccent,
        surface: cardBackgroundDark,
        error: statusCancelledDark,
        onPrimary: Color(0xFF121417),
        onSecondary: Colors.white,
        onSurface: textPrimaryDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackgroundDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderSubtleDark, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryDark,
          side: const BorderSide(color: borderSubtleDark),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF181B20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtleDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtleDark),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: primaryAccentLight, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: statusCancelledDark),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: statusCancelledDark, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: textSecondaryDark,
          fontSize: 14,
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w600, color: textPrimaryDark),
        titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimaryDark),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimaryDark),
        bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: textPrimaryDark),
        bodyMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: textSecondaryDark),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
        labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondaryDark),
      ),
      dividerTheme: const DividerThemeData(
        color: borderSubtleDark,
        thickness: 1,
      ),
    );
  }
}
