import 'package:flutter/material.dart';
import 'app_text_colors.dart';

class AppTextStyles {
  static TextStyle heading1(BuildContext context) => AppTextColors.style(
        context,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      );

  static TextStyle heading2(BuildContext context) => AppTextColors.style(
        context,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle heading3(BuildContext context) => AppTextColors.style(
        context,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle bodyLarge(BuildContext context) =>
      AppTextColors.style(context, fontSize: 16);

  static TextStyle bodySmall(BuildContext context) =>
      AppTextColors.style(context, fontSize: 14);

  static TextStyle label(BuildContext context) => AppTextColors.style(
        context,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  static TextStyle caption(BuildContext context) => AppTextColors.style(
        context,
        fontSize: 12,
        color: AppTextColors.muted(context),
      );
}
