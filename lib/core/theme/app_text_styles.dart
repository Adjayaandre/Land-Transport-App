import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTextStyles {
  static const heading1 = TextStyle(fontSize: 24, fontWeight: FontWeight.bold,   color: AppColors.textPrimary);
  static const heading2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600,   color: AppColors.textPrimary);
  static const heading3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600,   color: AppColors.textPrimary);
  static const bodyLarge  = TextStyle(fontSize: 16, color: AppColors.textPrimary);
  static const bodySmall  = TextStyle(fontSize: 14, color: AppColors.textPrimary);
  static const label    = TextStyle(fontSize: 14, fontWeight: FontWeight.w500,   color: AppColors.textPrimary);
  static const caption  = TextStyle(fontSize: 12, color: AppColors.textMuted);
}
