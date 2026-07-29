import 'package:flutter/material.dart';

class _Palette {
  final Color background;
  final Color surface;
  final Color primary;
  final Color primaryLight;
  final Color primarySoft;
  final Color accent;
  final Color accentSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color divider;
  final Color shadowColor;
  final Color statusOrange;
  final Color statusOrangeSoft;
  final Color statusRed;
  final Color statusRedSoft;
  final Color starYellow;
  final Color inputFill;

  const _Palette({
    required this.background,
    required this.surface,
    required this.primary,
    required this.primaryLight,
    required this.primarySoft,
    required this.accent,
    required this.accentSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.divider,
    required this.shadowColor,
    required this.statusOrange,
    required this.statusOrangeSoft,
    required this.statusRed,
    required this.statusRedSoft,
    required this.starYellow,
    required this.inputFill,
  });
}

const _light = _Palette(
  background: Color(0xFFF9F9FB),
  surface: Color(0xFFFFFFFF),
  primary: Color(0xFF0A7EA4),
  primaryLight: Color(0xFF3AA0C2),
  primarySoft: Color(0xFFE3F1F5),
  accent: Color(0xFF34C759),
  accentSoft: Color(0xFFE1F8E6),
  textPrimary: Color(0xFF1C1C1E),
  textSecondary: Color(0xFF8E8E93),
  border: Color(0xFFE5E5EA),
  divider: Color(0xFFE5E5EA),
  shadowColor: Color(0x14000000),
  statusOrange: Color(0xFFFF9500),
  statusOrangeSoft: Color(0xFFFFF3E0),
  statusRed: Color(0xFFFF3B30),
  statusRedSoft: Color(0xFFFFE9E7),
  starYellow: Color(0xFFFFC107),
  inputFill: Color(0xFFF0F1F3),
);

const _dark = _Palette(
  background: Color(0xFF000000),
  surface: Color(0xFF1C1C1E),
  primary: Color(0xFF3FC1E0),
  primaryLight: Color(0xFF6AD1E8),
  primarySoft: Color(0xFF12303A),
  accent: Color(0xFF30D158),
  accentSoft: Color(0xFF12301D),
  textPrimary: Color(0xFFF5F5F7),
  textSecondary: Color(0xFF8E8E93),
  border: Color(0xFF2C2C2E),
  divider: Color(0xFF2C2C2E),
  shadowColor: Color(0x66000000),
  statusOrange: Color(0xFFFF9F0A),
  statusOrangeSoft: Color(0xFF332208),
  statusRed: Color(0xFFFF453A),
  statusRedSoft: Color(0xFF331715),
  starYellow: Color(0xFFFFC107),
  inputFill: Color(0xFF2C2C2E),
);

class AppColors {
  static bool isDark = false;

  static Color background = _light.background;
  static Color surface = _light.surface;
  static Color primary = _light.primary;
  static Color primaryLight = _light.primaryLight;
  static Color primarySoft = _light.primarySoft;
  static Color accent = _light.accent;
  static Color accentSoft = _light.accentSoft;
  static Color textPrimary = _light.textPrimary;
  static Color textSecondary = _light.textSecondary;
  static Color border = _light.border;
  static Color divider = _light.divider;
  static Color shadowColor = _light.shadowColor;
  static Color statusOrange = _light.statusOrange;
  static Color statusOrangeSoft = _light.statusOrangeSoft;
  static Color statusRed = _light.statusRed;
  static Color statusRedSoft = _light.statusRedSoft;
  static Color starYellow = _light.starYellow;
  static Color inputFill = _light.inputFill;

  static Color get accentGreenLight => accent;
  static Color get accentGreen => accent;
  static Color get error => statusRed;
  static Color get star => starYellow;

  /// Reste blanc dans les deux themes (texte/icone sur fond colore plein).
  static Color get onColor => const Color(0xFFFFFFFF);

  static void setDark(bool dark) {
    final p = dark ? _dark : _light;
    isDark = dark;
    background = p.background;
    surface = p.surface;
    primary = p.primary;
    primaryLight = p.primaryLight;
    primarySoft = p.primarySoft;
    accent = p.accent;
    accentSoft = p.accentSoft;
    textPrimary = p.textPrimary;
    textSecondary = p.textSecondary;
    border = p.border;
    divider = p.divider;
    shadowColor = p.shadowColor;
    statusOrange = p.statusOrange;
    statusOrangeSoft = p.statusOrangeSoft;
    statusRed = p.statusRed;
    statusRedSoft = p.statusRedSoft;
    starYellow = p.starYellow;
    inputFill = p.inputFill;
  }
}

class AppShadows {
  static BoxShadow get soft => BoxShadow(
        color: AppColors.shadowColor,
        blurRadius: 24,
        offset: const Offset(0, 10),
      );

  static BoxShadow get button => BoxShadow(
        color: AppColors.isDark
            ? const Color(0x553FC1E0)
            : const Color(0x1A0A7EA4),
        blurRadius: 22,
        offset: const Offset(0, 10),
      );
}