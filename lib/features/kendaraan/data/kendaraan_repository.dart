import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../domain/kendaraan_model.dart';

class KendaraanRepository {
  static const _storageKey = 'kendaraan_list';
  final _uuid = const Uuid();

  Future<List<KendaraanModel>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => KendaraanModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<KendaraanModel?> getById(String id) async {
    final items = await getAll();
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<KendaraanModel> create({
    required String tipe,
    required String merk,
    required String model,
    required String tahun,
    required String nomorPlat,
  }) async {
    final item = KendaraanModel(
      id: _uuid.v4(),
      tipe: tipe,
      merk: merk,
      model: model,
      tahun: tahun,
      nomorPlat: nomorPlat,
    );
    final items = await getAll()..add(item);
    await _save(items);
    return item;
  }

  Future<KendaraanModel> update(KendaraanModel item) async {
    final items = await getAll();
    final index = items.indexWhere((k) => k.id == item.id);
    if (index == -1) throw StateError('Kendaraan tidak ditemukan');

    items[index] = item;
    await _save(items);
    return item;
  }

  Future<void> delete(String id) async {
    final items = await getAll()..removeWhere((k) => k.id == id);
    await _save(items);
  }

  Future<void> _save(List<KendaraanModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
