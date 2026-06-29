import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/kendaraan_repository.dart';
import 'kendaraan_model.dart';

final kendaraanRepositoryProvider =
    Provider<KendaraanRepository>((ref) => KendaraanRepository());

final kendaraanListProvider =
    FutureProvider<List<KendaraanModel>>((ref) async {
  return ref.read(kendaraanRepositoryProvider).getAll();
});

final kendaraanByIdProvider =
    FutureProvider.family<KendaraanModel?, String>((ref, id) async {
  return ref.read(kendaraanRepositoryProvider).getById(id);
});
