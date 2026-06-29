import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dashboard/domain/dashboard_provider.dart';

class PerjalananInput {
  final String driverId;
  final DateTime tanggal;
  final String pic;
  final String? namaKapal;
  final DateTime waktuJemput;
  final DateTime waktuSampai;
  final String titikJemput;
  final String titikTujuan;
  final double? odometerAkhir;
  final String? deskripsi;
  final bool dokumenLengkap;

  const PerjalananInput({
    required this.driverId,
    required this.tanggal,
    required this.pic,
    this.namaKapal,
    required this.waktuJemput,
    required this.waktuSampai,
    required this.titikJemput,
    required this.titikTujuan,
    this.odometerAkhir,
    this.deskripsi,
    this.dokumenLengkap = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_driver': driverId,
      'tanggal': _formatDate(tanggal),
      'pic': pic,
      if (namaKapal != null && namaKapal!.trim().isNotEmpty)
        'nama_kapal': namaKapal!.trim(),
      'waktu_jemput': waktuJemput.toUtc().toIso8601String(),
      'waktu_sampai': waktuSampai.toUtc().toIso8601String(),
      'titik_jemput': titikJemput.trim(),
      'titik_tujuan': titikTujuan.trim(),
      if (odometerAkhir != null) 'odometer_akhir': odometerAkhir,
      if (deskripsi != null && deskripsi!.trim().isNotEmpty)
        'deskripsi': deskripsi!.trim(),
      'status': 'berlangsung',
      'dokumen_lengkap': dokumenLengkap,
    };
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class TripRepository {
  final _client = Supabase.instance.client;

  Future<void> create(PerjalananInput input) async {
    await _client.from('perjalanan').insert(input.toJson());
  }
}

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository();
});

/// Simpan perjalanan + refresh dashboard.
final savePerjalananProvider =
    Provider<Future<void> Function(PerjalananInput)>((ref) {
  return (input) async {
    await ref.read(tripRepositoryProvider).create(input);
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(perjalananTerbaruProvider);
  };
});
