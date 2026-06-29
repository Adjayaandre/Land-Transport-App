import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/driver_repository.dart';
import 'driver_model.dart';

final driverRepositoryProvider =
    Provider<DriverRepository>((ref) => DriverRepository());

final driverListProvider = FutureProvider<List<DriverModel>>((ref) async {
  return ref.read(driverRepositoryProvider).getAll();
});

final driverByIdProvider =
    FutureProvider.family<DriverModel?, String>((ref, id) async {
  return ref.read(driverRepositoryProvider).getById(id);
});
