import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kBackgroundColor = Color(0xFFF7F8FA);
const Color kCardColor = Colors.white;
const Color kPrimaryColor = Color(0xFF0B4F5C);
const Color kAccentGreen = Color(0xFFD9F2E3);
const Color kAccentGreenText = Color(0xFF1F7A4D);
const Color kTextPrimary = Color(0xFF1A1A1A);
const Color kTextSecondary = Color(0xFF8A8F98);
const Color kDividerColor = Color(0xFFE7E9EC);
const Color kDangerColor = Color(0xFFE24C4C);
const Color kDangerSoft = Color(0xFFFCEAEA);
const Color kInputFill = Color(0xFFF0F1F3);
const Color kStarGold = Color(0xFFFFC107);

const Color kBackgroundColorDark = Color(0xFF0B0F14);
const Color kCardColorDark = Color(0xFF141A21);
const Color kPrimaryColorDark = Color(0xFF3AA7BB);
const Color kAccentGreenDark = Color(0xFF14301F);
const Color kAccentGreenTextDark = Color(0xFF4FD98C);
const Color kTextPrimaryDark = Color(0xFFF5F7FA);
const Color kTextSecondaryDark = Color(0xFF8A97A8);
const Color kDividerColorDark = Color(0xFF232B35);
const Color kDangerColorDark = Color(0xFFEF4444);
const Color kDangerSoftDark = Color(0xFF2A1414);
const Color kInputFillDark = Color(0xFF1A222C);
const Color kStarGoldDark = Color(0xFFFFC107);

class AppShadow {
  static const BoxShadow card = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 20,
    offset: Offset(0, 8),
  );
}

class AppTheme {
  static ThemeData light() => _build(isDark: false);
  static ThemeData dark() => _build(isDark: true);

  static ThemeData _build({required bool isDark}) {
    final background = isDark ? kBackgroundColorDark : kBackgroundColor;
    final card = isDark ? kCardColorDark : kCardColor;
    final primary = isDark ? kPrimaryColorDark : kPrimaryColor;
    final textPrimary = isDark ? kTextPrimaryDark : kTextPrimary;
    final textSecondary = isDark ? kTextSecondaryDark : kTextSecondary;
    final divider = isDark ? kDividerColorDark : kDividerColor;
    final inputFill = isDark ? kInputFillDark : kInputFill;
    final danger = isDark ? kDangerColorDark : kDangerColor;

    final baseTextTheme = GoogleFonts.interTextTheme();

    final textTheme = baseTextTheme.copyWith(
      titleLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: textPrimary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: background,
      splashColor: primary.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light())
          .copyWith(
        primary: primary,
        secondary: kAccentGreenText,
        surface: card,
        error: danger,
        outline: divider,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: danger, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: card,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: textPrimary),
    );
  }
}