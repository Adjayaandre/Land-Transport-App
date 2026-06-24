import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const StatCard({super.key, required this.label, required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [Icon(icon, color: color, size: 32), Text('$count', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), Text(label)],
        ),
      ),
    );
  }
}
