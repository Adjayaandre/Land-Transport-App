import 'package:flutter/material.dart';
import '../core/theme/app_text_colors.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyState({super.key, required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: context.adaptiveTextMuted),
      const SizedBox(height: 16),
      Text(message, style: AppTextColors.style(context, fontSize: 16)),
    ]));
  }
}
