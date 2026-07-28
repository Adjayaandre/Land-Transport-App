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
    final rows = List<Map<String, dynamic>>.from(data as List);

    // View `ringkasan_perjalanan` tidak menyertakan merek/model kendaraan,
    // jadi ambil terpisah dari tabel `kendaraan` berdasarkan nomor polisi
    // lalu gabungkan ke setiap baris sebelum di-parse.
    // Nomor polisi dinormalisasi (trim + uppercase) agar perbedaan spasi
    // atau huruf besar/kecil antar tabel tidak menyebabkan gagal cocok.
    String normalize(String s) => s.trim().toUpperCase();

    final nomorPolisiList = rows
        .map((r) => r['nomor_polisi'] as String?)
        .whereType<String>()
        .map(normalize)
        .toSet()
        .toList();

    final kendaraanByNopol = <String, Map<String, dynamic>>{};
    if (nomorPolisiList.isNotEmpty) {
      final kendaraanRows = await _db
          .from('kendaraan')
          .select('nomor_polisi, merek, model')
          .inFilter('nomor_polisi', nomorPolisiList);
      for (final k in List<Map<String, dynamic>>.from(kendaraanRows as List)) {
        final nopol = k['nomor_polisi'] as String?;
        if (nopol != null) kendaraanByNopol[normalize(nopol)] = k;
      }
    }

    return rows.map((r) {
      final rawNopol = r['nomor_polisi'] as String?;
      final kendaraan =
          rawNopol != null ? kendaraanByNopol[normalize(rawNopol)] : null;
      final merged = {
        ...r,
        if (kendaraan != null) 'merek': kendaraan['merek'],
        if (kendaraan != null) 'model': kendaraan['model'],
      };
      return PerjalananSingkat.fromJson(merged);
    }).toList();
  }
}