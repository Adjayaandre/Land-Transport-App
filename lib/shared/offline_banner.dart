import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final int pendingCount;
  const OfflineBanner({super.key, this.pendingCount = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF57F17),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(children: [
        const Icon(Icons.wifi_off, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(
          pendingCount > 0 ? 'Mode Offline — $pendingCount data menunggu sinkronisasi' : 'Mode Offline',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        )),
      ]),
    );
  }
}
