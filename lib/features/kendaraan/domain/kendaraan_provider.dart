import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/kendaraan_repository.dart';
import 'kendaraan_model.dart';

final kendaraanRepositoryProvider =
    Provider<KendaraanRepository>((ref) => KendaraanRepository());

class KendaraanListNotifier
    extends AutoDisposeAsyncNotifier<List<KendaraanModel>> {
  @override
  Future<List<KendaraanModel>> build() async {
    return ref.read(kendaraanRepositoryProvider).getAll();
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(
      () => ref.read(kendaraanRepositoryProvider).getAll(),
    );
  }

  Future<void> deleteByIds(Set<String> ids) async {
    if (ids.isEmpty) return;

    final repo = ref.read(kendaraanRepositoryProvider);
    await Future.wait(ids.map(repo.delete));

    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(
        current.where((k) => !ids.contains(k.id)).toList(),
      );
    } else {
      await reload();
    }
  }
}

final kendaraanListProvider = AsyncNotifierProvider.autoDispose<
    KendaraanListNotifier, List<KendaraanModel>>(
  KendaraanListNotifier.new,
);

final kendaraanByIdProvider =
    FutureProvider.family<KendaraanModel?, String>((ref, id) async {
  return ref.read(kendaraanRepositoryProvider).getById(id);
});
