import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_text_colors.dart';

enum TripStatus { ongoing, completed, pending, cancelled }

class AppBadge extends StatelessWidget {
  final TripStatus status;

  const AppBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      TripStatus.ongoing => ('Ongoing', AppColors.ongoingBg, AppColors.ongoing),
      TripStatus.completed => (
          'Completed',
          AppColors.completedBg,
          AppColors.completed
        ),
      TripStatus.pending => ('Pending', AppColors.pendingBg, AppColors.primary),
      TripStatus.cancelled => (
          'Cancelled',
          AppColors.cancelledBg,
          AppColors.cancelled
        ),
    };
    final textColor = AppTextColors.isDark(context) ? Colors.white : fg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }
}
