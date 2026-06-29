import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/domain/auth_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  final String currentPath;
  const AppShell({super.key, required this.child, required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final role = user?.role ?? '';
    final isSuperadmin = role == 'superadmin';
    final hideFab = currentPath == AppRoutes.tambahPerjalanan;

    return Scaffold(
      body: child,
      floatingActionButton: hideFab
          ? const SizedBox(width: 56, height: 56)
          : FloatingActionButton(
              onPressed: () => context.go(AppRoutes.tambahPerjalanan),
              backgroundColor: AppColors.primary,
              elevation: 2,
              highlightElevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: isSuperadmin
          ? _SuperadminNav(currentPath: currentPath)
          : _DefaultNav(currentPath: currentPath),
    );
  }
}

// ── Nav Superadmin: Home | Kelola Kendaraan | [FAB] | Kelola Driver | Profil ─

class _SuperadminNav extends StatelessWidget {
  final String currentPath;
  const _SuperadminNav({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 64,
      padding: EdgeInsets.zero,
      color: AppColors.primary,
      elevation: 8,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: Row(
        children: [
          Expanded(
            child: _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              route: AppRoutes.dashboard,
              routeName: AppRoutes.dashboardName,
              currentPath: currentPath,
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.directions_car_rounded,
              label: 'Kelola Kendaraan',
              route: AppRoutes.kelolaKendaraan,
              routeName: AppRoutes.kelolaKendaraanName,
              activePaths: const [
                AppRoutes.kelolaKendaraan,
                AppRoutes.tambahKendaraan,
              ],
              currentPath: currentPath,
            ),
          ),
          const SizedBox(width: 56),
          Expanded(
            child: _NavItem(
              icon: Icons.person_add_rounded,
              label: 'Kelola Driver',
              route: AppRoutes.kelolaDriver,
              routeName: AppRoutes.kelolaDriverName,
              activePaths: const [
                AppRoutes.kelolaDriver,
                AppRoutes.tambahDriver,
              ],
              currentPath: currentPath,
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profil',
              route: AppRoutes.profil,
              routeName: AppRoutes.profilName,
              currentPath: currentPath,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nav Admin/Driver: Home | [FAB] | Profil ──────────────────────────────────

class _DefaultNav extends StatelessWidget {
  final String currentPath;
  const _DefaultNav({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 64,
      padding: EdgeInsets.zero,
      color: AppColors.primary,
      elevation: 8,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              route: AppRoutes.dashboard,
              routeName: AppRoutes.dashboardName,
              currentPath: currentPath,
            ),
          ),
          const SizedBox(width: 56),
          Expanded(
            child: _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profil',
              route: AppRoutes.profil,
              routeName: AppRoutes.profilName,
              currentPath: currentPath,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nav Item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String? routeName;
  final String currentPath;
  final List<String>? activePaths;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentPath,
    this.routeName,
    this.activePaths,
  });

  @override
  Widget build(BuildContext context) {
    final paths = activePaths ?? [route];
    final active = paths.contains(currentPath);
    return InkWell(
      onTap: () {
        if (routeName != null) {
          context.goNamed(routeName!);
        } else {
          context.go(route);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: active
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              height: 1.1,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color:
                  active ? Colors.white : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
