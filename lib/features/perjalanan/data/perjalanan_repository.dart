import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dashboard/domain/dashboard_provider.dart';

class PerjalananInput {
  final String driverId;
  final String kendaraanId;
  final DateTime tanggal;
  final String pic;
  final String? namaKapal;
  final DateTime waktuJemput;
  final DateTime waktuTiba;
  final String titikJemput;
  final String titikTujuan;
  final double? odometerAkhir;
  final String? deskripsi;

  const PerjalananInput({
    required this.driverId,
    required this.kendaraanId,
    required this.tanggal,
    required this.pic,
    this.namaKapal,
    required this.waktuJemput,
    required this.waktuTiba,
    required this.titikJemput,
    required this.titikTujuan,
    this.odometerAkhir,
    this.deskripsi,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_driver': driverId,
      'id_kendaraan': kendaraanId,
      'tanggal': _formatDate(tanggal),
      'pic': pic,
      if (namaKapal != null && namaKapal!.trim().isNotEmpty)
        'nama_kapal': namaKapal!.trim(),
      'waktu_jemput': _formatTime(waktuJemput),
      'waktu_tiba': _formatTime(waktuTiba),
      'titik_jemput': titikJemput.trim(),
      'titik_tujuan': titikTujuan.trim(),
      if (odometerAkhir != null) 'odometer_akhir': odometerAkhir,
      if (deskripsi != null && deskripsi!.trim().isNotEmpty)
        'deskripsi': deskripsi!.trim(),
    };
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
}

class TripRepository {
  final _client = Supabase.instance.client;

  Future<void> create(PerjalananInput input) async {
    await _client.from('perjalanan').insert(input.toJson());
  }

  /// Ambil semua perjalanan yang sudah selesai (ada tanda tangan), terbaru dulu.
  Future<List<Map<String, dynamic>>> fetchSemua() async {
    final data = await _client
        .from('ringkasan_perjalanan')
        .select()
        .order('dibuat_pada', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final result =
        await _client.from('perjalanan').update(data).eq('id', id).select();
    if ((result as List).isEmpty) {
      throw Exception(
          'Tidak ada data terubah. Kemungkinan akses ditolak oleh RLS.');
    }
  }

  Future<void> delete(String id) async {
    final result =
        await _client.from('perjalanan').delete().eq('id', id).select();
    if ((result as List).isEmpty) {
      throw Exception(
          'Tidak ada data terhapus. Kemungkinan akses ditolak oleh RLS.');
    }
  }

  Future<void> updateOdometerKendaraan(String kendaraanId, double odometer) async {
    await _client
        .from('kendaraan')
        .update({'odometer_sekarang': odometer})
        .eq('id', kendaraanId);
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