import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  Color get _color => switch (status) {
    'ongoing'     => AppColors.statusOngoing,
    'completed'   => AppColors.statusCompleted,
    'cancelled'   => AppColors.statusCancelled,
    _             => AppColors.statusPreparation,
  };

  String get _label => switch (status) {
    'ongoing'     => 'Berlangsung',
    'completed'   => 'Selesai',
    'cancelled'   => 'Dibatalkan',
    _             => 'Persiapan',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: _color)),
      child: Text(_label, style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
