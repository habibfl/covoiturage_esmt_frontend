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
  background: Color(0xFFF7F8FA),
  surface: Color(0xFFFFFFFF),
  primary: Color(0xFF0B4F5C),
  primaryLight: Color(0xFF14707F),
  primarySoft: Color(0xFFE3EEF0),
  accent: Color(0xFF1F7A4D),
  accentSoft: Color(0xFFD9F2E3),
  textPrimary: Color(0xFF1A1A1A),
  textSecondary: Color(0xFF8A8F98),
  border: Color(0xFFE7E9EC),
  divider: Color(0xFFE7E9EC),
  shadowColor: Color(0x0D000000),
  statusOrange: Color(0xFFF59E0B),
  statusOrangeSoft: Color(0xFFFFFBEB),
  statusRed: Color(0xFFE24C4C),
  statusRedSoft: Color(0xFFFCEAEA),
  starYellow: Color(0xFFFFC107),
  inputFill: Color(0xFFF0F1F3),
);

const _dark = _Palette(
  background: Color(0xFF0B0F14),
  surface: Color(0xFF141A21),
  primary: Color(0xFF3AA7BB),
  primaryLight: Color(0xFF5FC2D4),
  primarySoft: Color(0xFF16303A),
  accent: Color(0xFF4FD98C),
  accentSoft: Color(0xFF14301F),
  textPrimary: Color(0xFFF5F7FA),
  textSecondary: Color(0xFF8A97A8),
  border: Color(0xFF232B35),
  divider: Color(0xFF1C232B),
  shadowColor: Color(0x66000000),
  statusOrange: Color(0xFFF59E0B),
  statusOrangeSoft: Color(0xFF2A2013),
  statusRed: Color(0xFFEF4444),
  statusRedSoft: Color(0xFF2A1414),
  starYellow: Color(0xFFFFC107),
  inputFill: Color(0xFF1A222C),
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
        blurRadius: 20,
        offset: const Offset(0, 8),
      );

  static BoxShadow get button => BoxShadow(
        color: AppColors.isDark
            ? const Color(0x553AA7BB)
            : const Color(0x1A0B4F5C),
        blurRadius: 20,
        offset: const Offset(0, 10),
      );
}