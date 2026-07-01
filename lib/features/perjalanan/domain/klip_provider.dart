import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/klip_repository.dart';
import 'klip_model.dart';

final klipRepositoryProvider =
    Provider<KlipRepository>((ref) => KlipRepository());

final klipAktifProvider =
    FutureProvider.autoDispose.family<KlipPerjalanan?, String>(
  (ref, idKendaraan) =>
      ref.read(klipRepositoryProvider).getKlipAktif(idKendaraan),
);