import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/klip_model.dart';

class KlipRepository {
  final _db = Supabase.instance.client;

  /// Ambil klip aktif untuk kendaraan tertentu (null jika belum ada).
  Future<KlipPerjalanan?> getKlipAktif(String idKendaraan) async {
    final data = await _db
        .from('klip_perjalanan')
        .select()
        .eq('id_kendaraan', idKendaraan)
        .eq('status', 'aktif')
        .order('dibuat_pada', ascending: false)
        .limit(1)
        .maybeSingle();
    if (data == null) return null;
    return KlipPerjalanan.fromJson(data);
  }

  /// Buat klip baru untuk kendaraan.
  Future<KlipPerjalanan> buatKlipBaru({
    required String idKendaraan,
    required String dibuatOleh,
  }) async {
    final result = await _db.from('klip_perjalanan').insert({
      'id_kendaraan': idKendaraan,
      'dibuat_oleh':  dibuatOleh,
      'status':       'aktif',
    }).select().single();
    return KlipPerjalanan.fromJson(result);
  }

  /// Tutup klip aktif — upload foto nota ke Storage lalu update record.
  Future<void> tutupKlip({
    required String klipId,
    required double odometerTutup,
    required Uint8List fotoNotaBytes,
  }) async {
    const bucket = 'foto-perjalanan';
    final path = 'nota-bensin/$klipId-${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _db.storage.from(bucket).uploadBinary(
          path,
          fotoNotaBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

    final url = _db.storage.from(bucket).getPublicUrl(path);

    await _db.from('klip_perjalanan').update({
      'status':         'tutup',
      'odometer_tutup': odometerTutup,
      'foto_nota_url':  url,
      'foto_nota_path': path,
      'ditutup_pada':   DateTime.now().toIso8601String(),
    }).eq('id', klipId);
  }
}