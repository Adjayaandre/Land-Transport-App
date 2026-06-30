import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dashboard_repository.dart';
import 'dashboard_model.dart';

final _repo = Provider((_) => DashboardRepository());

final dashboardStatsProvider = FutureProvider<DashboardStats>(
  (ref) => ref.read(_repo).fetchStats(),
);

final perjalananTerbaruProvider = FutureProvider<List<PerjalananSingkat>>(
  (ref) => ref.read(_repo).fetchTerbaru(),
);

final kendaraanStatusProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(_repo).fetchKendaraanStatus(),
);