import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/kendaraan_model.dart';

class KendaraanRepository {
  final _db = Supabase.instance.client;

  Future<List<KendaraanModel>> getAll() async {
    final data = await _db
        .from('kendaraan')
        .select()
        .order('nomor_polisi');
    return (data as List).map((e) => KendaraanModel.fromJson(e)).toList();
  }

  Future<KendaraanModel?> getById(String id) async {
    final data = await _db
        .from('kendaraan')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return KendaraanModel.fromJson(data);
  }

  Future<KendaraanModel> create({
    required String nomorPlat,
    required String merek,
    required String model,
    String? warna,
    double odometerSekarang = 0,
    bool aktif = true,
    String? keterangan,
  }) async {
    final result = await _db.from('kendaraan').insert({
      'nomor_polisi': nomorPlat.trim(),
      'merek': merek.trim(),
      'model': model.trim(),
      if (warna != null && warna.trim().isNotEmpty) 'warna': warna.trim(),
      'odometer_sekarang': odometerSekarang,
      'aktif': aktif,
      if (keterangan != null && keterangan.trim().isNotEmpty)
        'keterangan': keterangan.trim(),
    }).select().single();
    return KendaraanModel.fromJson(result);
  }

  Future<KendaraanModel> update(KendaraanModel item) async {
    final data = item.toJson()..remove('id');
    final result = await _db
        .from('kendaraan')
        .update(data)
        .eq('id', item.id)
        .select()
        .single();
    return KendaraanModel.fromJson(result);
  }

  Future<void> delete(String id) async {
    await _db.from('kendaraan').delete().eq('id', id);
  }
}