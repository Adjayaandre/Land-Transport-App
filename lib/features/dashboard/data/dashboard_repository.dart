import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/dashboard_model.dart';

class DashboardRepository {
  final _db = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchKendaraanStatus() async {
    final data = await _db
        .from('kendaraan')
        .select('id, nomor_polisi, merek, model, aktif')
        .order('nomor_polisi');
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<DashboardStats> fetchStats() async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    final r1 = await _db
        .from('perjalanan')
        .select('id')
        .eq('tanggal', today)
        .count();

    final jarakRows = await _db
        .from('ringkasan_perjalanan')
        .select('jarak');

    final totalKm = (jarakRows as List).fold<double>(
      0,
      (sum, row) => sum + ((row['jarak'] as num?)?.toDouble() ?? 0),
    );

    return DashboardStats(
      perjalananHariIni: r1.count,
      totalKmSelesai: totalKm,
    );
  }

  Future<List<PerjalananSingkat>> fetchTerbaru() async {
    final data = await _db
        .from('ringkasan_perjalanan')
        .select()
        .order('dibuat_pada', ascending: false)
        .limit(5);
    return (data as List).map((e) => PerjalananSingkat.fromJson(e)).toList();
  }
}