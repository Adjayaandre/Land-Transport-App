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

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen(this.title);
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.construction_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Sedang dalam pengembangan',
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ]),
      );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final path   = state.uri.path;
      final status = authState.status;

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
      // Tanpa shell
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

      // Dengan shell (sidebar)
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DashboardScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 250),
            ),
          ),
          GoRoute(
            path: AppRoutes.tambahPerjalanan,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const _PlaceholderScreen('Tambah Perjalanan'),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 250),
            ),
          ),
          GoRoute(
            path: AppRoutes.tambahKendaraan,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const _PlaceholderScreen('Tambah Kendaraan'),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 250),
            ),
          ),
          GoRoute(
            path: AppRoutes.tambahDriver,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const _PlaceholderScreen('Tambah Driver'),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 250),
            ),
          ),
          GoRoute(
            path: AppRoutes.riwayat,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const _PlaceholderScreen('Riwayat Perjalanan'),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 250),
            ),
          ),
          GoRoute(
            path: AppRoutes.cari,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const _PlaceholderScreen('Cari Kegiatan'),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 250),
            ),
          ),
          GoRoute(
            path: AppRoutes.profil,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const _PlaceholderScreen('Profil'),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 250),
            ),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Halaman tidak ditemukan: ${state.uri}')),
    ),
  );
});