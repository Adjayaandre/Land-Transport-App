import 'package:flutter/material.dart';

abstract class AppColors {
  // Primary
  static const Color primary = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFF2B4FA8);
  static const Color primaryDark = Color(0xFF152B6B);

  // Accent
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFEF3C7);

  // Background
  static const Color background = Color(0xFFF0F2F5);
  static const Color surface = Colors.white;

  // Status
  static const Color ongoing = Color(0xFFF59E0B);
  static const Color ongoingBg = Color(0xFFFEF3C7);
  static const Color completed = Color(0xFF16A34A);
  static const Color completedBg = Color(0xFFD1FAE5);
  static const Color cancelled = Color(0xFFDC2626);
  static const Color cancelledBg = Color(0xFFFEE2E2);
  static const Color pendingBg = Color(0xFFE0E7FF);

  // Compatibility aliases used by older screens/widgets.
  static const Color secondary = primaryLight;
  static const Color success = completed;
  static const Color warning = ongoing;
  static const Color danger = cancelled;
  static const Color cardBg = surface;
  static const Color inputBg = inputFill;

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Colors.white;

  // Border
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderStrong = Color(0xFFD1D5DB);

  // Input
  static const Color inputFill = Color(0xFFF9FAFB);
}
