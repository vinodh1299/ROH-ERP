// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand — purple/violet from the Figma design
  static const Color primary = Color(0xFF7B2FBE);
  static const Color primaryLight = Color(0xFF9C4FD6);
  static const Color primaryDark = Color(0xFF5A1F8A);

  // Gradient used in welcome card
  static const LinearGradient welcomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7B2FBE), Color(0xFF4A1080)],
  );

  // Sidebar
  static const Color sidebarBg = Color(0xFFFFFFFF);
  static const Color sidebarSelected = Color(0xFF7B2FBE);
  static const Color sidebarSelectedBg = Color(0xFFF3E8FF);

  // Status colours
  static const Color statusPending = Color(0xFFFF9800);
  static const Color statusPendingBg = Color(0xFFFFF3E0);
  static const Color statusActive = Color(0xFF4CAF50);
  static const Color statusActiveBg = Color(0xFFE8F5E9);
  static const Color statusDeactivated = Color(0xFFE53935);
  static const Color statusDeactivatedBg = Color(0xFFFFEBEE);

  // Background
  static const Color scaffold = Color(0xFFF5F5F5);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // Accent teal used on staff card
  static const Color accentTeal = Color(0xFF00BCD4);

  // Divider
  static const Color divider = Color(0xFFE5E7EB);

  // Table header text
  static const Color tableHeaderText = Color(0xFF7B2FBE);
}
