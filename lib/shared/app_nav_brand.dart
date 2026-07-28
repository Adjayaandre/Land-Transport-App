import 'package:flutter/material.dart';

/// Widget logo LTD — menampilkan gambar logo dari assets.
/// Digunakan sebagai brand pada AppBar dan sidebar.
class AppNavBrand extends StatelessWidget {
  final double size;

  const AppNavBrand({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_ltd.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// Logo LTD dalam Container putih untuk dipakai sebagai
/// leading icon pada AppBar (posisi kiri, simetris).
class AppNavBrandLeading extends StatelessWidget {
  const AppNavBrandLeading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/logo_ltd.png',
            width: 34,
            height: 34,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}