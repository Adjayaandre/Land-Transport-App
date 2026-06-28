import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/dashboard_model.dart';

class DashboardRepository {
  final _db = Supabase.instance.client;

  Future<DashboardStats> fetchStats() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final r1 = await _db.from('perjalanan').select('id').count();
    final r2 = await _db.from('perjalanan').select('id').eq('tanggal', today).count();
    return DashboardStats(
      totalPerjalanan:   r1.count,
      perjalananHariIni: r2.count,
    );
  }

  Future<List<PerjalananSingkat>> fetchTerbaru() async {
    final data = await _db
        .from('ringkasan_perjalanan')
        .select()
        .order('dibuat_pada', ascending: false)
        .limit(10);
    return (data as List).map((e) => PerjalananSingkat.fromJson(e)).toList();
  }
}