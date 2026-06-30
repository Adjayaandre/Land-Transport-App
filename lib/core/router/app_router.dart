import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';
import '../../widgets/app_shell.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/profil/presentation/profil_screen.dart';
import '../../features/pengaturan/presentation/pengaturan_screen.dart';
import '../../features/perjalanan/presentation/tambah_perjalanan_screen.dart';
import '../../features/perjalanan/presentation/riwayat_perjalanan_screen.dart';
import '../../features/perjalanan/presentation/edit_perjalanan_screen.dart';
import '../../features/kendaraan/presentation/kelola_kendaraan_screen.dart';
import '../../features/kendaraan/presentation/tambah_kendaraan_screen.dart';
import '../../features/driver/presentation/kelola_driver_screen.dart';
import '../../features/driver/presentation/tambah_driver_screen.dart';

CustomTransitionPage<void> _fadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 250),
  );
}

List<RouteBase> _shellRoutes() => [
      GoRoute(
        name: AppRoutes.dashboardName,
        path: AppRoutes.dashboard,
        pageBuilder: (_, state) => _fadePage(
          key: state.pageKey,
          child: const DashboardScreen(),
        ),
      ),
      GoRoute(
        name: AppRoutes.tambahPerjalananName,
        path: AppRoutes.tambahPerjalanan,
        pageBuilder: (_, state) => _fadePage(
          key: state.pageKey,
          child: const TambahPerjalananScreen(),
        ),
      ),
      GoRoute(
        name: AppRoutes.riwayatPerjalananName,
        path: AppRoutes.riwayatPerjalanan,
        pageBuilder: (_, state) => _fadePage(
          key: state.pageKey,
          child: const RiwayatPerjalananScreen(),
        ),
      ),
      GoRoute(
        name: AppRoutes.editPerjalananName,
        path: AppRoutes.editPerjalanan,
        pageBuilder: (_, state) => _fadePage(
          key: state.pageKey,
          child: EditPerjalananScreen(
            trip: state.extra as Map<String, dynamic>,
          ),
        ),
      ),
      GoRoute(
        name: AppRoutes.kelolaKendaraanName,
        path: AppRoutes.kelolaKendaraan,
        pageBuilder: (_, state) => _fadePage(
          key: state.pageKey,
          child: const KelolaKendaraanScreen(),
        ),
      ),
      GoRoute(
        name: AppRoutes.tambahKendaraanName,
        path: AppRoutes.tambahKendaraan,
        pageBuilder: (_, state) => _fadePage(
          key: state.pageKey,
          child: TambahKendaraanScreen(
            kendaraanId: state.uri.queryParameters['id'],
          ),
        ),
      ),
      GoRoute(
        name: AppRoutes.kelolaDriverName,
        path: AppRoutes.kelolaDriver,
        pageBuilder: (_, state) => _fadePage(
          key: state.pageKey,
          child: const KelolaDriverScreen(),
        ),
      ),
      GoRoute(
        name: AppRoutes.tambahDriverName,
        path: AppRoutes.tambahDriver,
        pageBuilder: (_, state) => _fadePage(
          key: state.pageKey,
          child: TambahDriverScreen(
            driverId: state.uri.queryParameters['id'],
          ),
        ),
      ),
      GoRoute(
        name: AppRoutes.profilName,
        path: AppRoutes.profil,
        pageBuilder: (_, state) => _fadePage(
          key: state.pageKey,
          child: const ProfilScreen(),
        ),
      ),
      GoRoute(
        name: AppRoutes.pengaturanName,
        path: AppRoutes.pengaturan,
        pageBuilder: (_, state) => _fadePage(
          key: state.pageKey,
          child: const PengaturanScreen(),
        ),
      ),
    ];

final routerProvider = Provider<GoRouter>((ref) {
  // Hanya rebuild router saat status login berubah, bukan saat profil di-update
  ref.watch(authProvider.select((s) => s.status));

  final router = GoRouter(
    debugLogDiagnostics: kDebugMode,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final path = state.uri.path;
      final status = ref.read(authProvider).status;

      if (status == AuthStatus.initial || status == AuthStatus.loading) {
        return path != AppRoutes.splash ? AppRoutes.splash : null;
      }
      if (status == AuthStatus.authenticated) {
        if (path == AppRoutes.splash || path == AppRoutes.login) {
          return AppRoutes.dashboard;
        }
        return null;
      }
      if (path != AppRoutes.login && path != AppRoutes.splash) {
        return AppRoutes.login;
      }
      if (path == AppRoutes.splash) return AppRoutes.login;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentPath: state.uri.path,
          child: child,
        ),
        routes: _shellRoutes(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Halaman tidak ditemukan: ${state.uri.path}'),
      ),
    ),
  );

  ref.onDispose(router.dispose);
  return router;
});