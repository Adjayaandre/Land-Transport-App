import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Avatar ikon kendaraan dengan warna konsisten berdasarkan status.
/// Hijau = Tersedia (aktif), Kuning = Tidak Tersedia (tidak aktif).
class VehicleAvatar extends StatelessWidget {
  final bool aktif;
  final double size;
  final double iconSize;
  final double borderRadius;

  const VehicleAvatar({
    super.key,
    required this.aktif,
    this.size = 44,
    this.iconSize = 22,
    this.borderRadius = 10,
  });

  static Color iconColor(bool aktif) =>
      aktif ? AppColors.completed : const Color(0xFFF59E0B);

  static Color bgColor(bool aktif, {bool isDark = false}) {
    if (aktif) {
      return isDark
          ? const Color(0xFF1B4332)
          : AppColors.completed.withValues(alpha: 0.12);
    } else {
      return isDark
          ? const Color(0xFF4A3B0F)
          : const Color(0xFFF59E0B).withValues(alpha: 0.12);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor(aktif, isDark: isDark),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.directions_car_rounded,
        color: iconColor(aktif),
        size: iconSize,
      ),
    );
  }
}