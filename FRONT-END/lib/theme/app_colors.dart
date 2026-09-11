// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary (Rich Purple #AB47BC)
  static const Color primary = Color(0xFFAB47BC);
  static const Color primaryDark = Color(0xFF7B1FA2);
  static const Color primaryLight = Color(0xFFF3E5F5);

  // Neutrals (do the heavy lifting — most of the UI should be these)
  static const Color background = Color(0xFFFAFAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E5E3);
  static const Color textPrimary = Color(0xFF1F2421);
  static const Color textSecondary = Color(0xFF6B716C);
  static const Color textDisabled = Color(0xFFA8ACA9);

  // Status colors — muted, not saturated (used ONLY for status, never decoration)
  static const Color success = Color(0xFF5C8268);   // reuse primary-dark tone, not bright green
  static const Color warning = Color(0xFFC98A3E);   // muted amber, not bright orange
  static const Color error = Color(0xFFB55757);     // muted red, not alarm-red
  static const Color info = Color(0xFF5B7A96);      // muted blue

  // Dark mode tokens
  static const Color backgroundDark = Color(0xFF141715);
  static const Color surfaceDark = Color(0xFF1D211E);
  static const Color borderDark = Color(0xFF2C312D);
  static const Color textPrimaryDark = Color(0xFFF2F2F0);
  static const Color textSecondaryDark = Color(0xFFA8ACA9);

  // Muted status backgrounds (12% opacity on white background)
  static const Color successBg = Color(0xFFEDF4EF);
  static const Color warningBg = Color(0xFFFAF3EB);
  static const Color errorBg = Color(0xFFF9EFEF);
  static const Color infoBg = Color(0xFFEEF3F7);

  // Aliases for seamless migration from legacy references
  static const Color scaffold = background;
  static const Color cardBg = surface;
  static const Color divider = border;
  static const Color textHint = textDisabled;
  static const Color sidebarBg = surface;
  static const Color sidebarSelected = primary;
  static const Color sidebarSelectedBg = primaryLight;
  static const Color tableHeaderText = textPrimary;
  static const Color accentTeal = primary;

  // Status aliases
  static const Color statusPending = warning;
  static const Color statusPendingBg = warningBg;
  static const Color statusActive = success;
  static const Color statusActiveBg = successBg;
  static const Color statusDeactivated = error;
  static const Color statusDeactivatedBg = errorBg;

  // Legacy welcome gradient replaced with calm solid tones
  static const LinearGradient welcomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
}
