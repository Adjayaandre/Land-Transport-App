import 'package:flutter/material.dart';

/// Warna teks yang menyesuaikan mode terang/gelap.
abstract class AppTextColors {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color primary(BuildContext context) =>
      isDark(context) ? Colors.white : const Color(0xFF111827);

  static Color secondary(BuildContext context) =>
      isDark(context) ? Colors.white : const Color(0xFF6B7280);

  static Color muted(BuildContext context) =>
      isDark(context) ? Colors.white : const Color(0xFF9CA3AF);

  static TextStyle style(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? primary(context),
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}

extension AppTextColorsExtension on BuildContext {
  Color get adaptiveText => AppTextColors.primary(this);

  Color get adaptiveTextSecondary => AppTextColors.secondary(this);

  Color get adaptiveTextMuted => AppTextColors.muted(this);
}
