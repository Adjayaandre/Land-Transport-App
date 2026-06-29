import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_text_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  Color get _color => switch (status) {
        'ongoing' => AppColors.primary,
        'completed' => AppColors.success,
        'cancelled' => AppColors.danger,
        _ => AppColors.warning,
      };

  String get _label => switch (status) {
        'ongoing' => 'Berlangsung',
        'completed' => 'Selesai',
        'cancelled' => 'Dibatalkan',
        _ => 'Persiapan',
      };

  @override
  Widget build(BuildContext context) {
    final textColor = AppTextColors.isDark(context) ? Colors.white : _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color),
      ),
      child: Text(_label,
          style: TextStyle(
              color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
