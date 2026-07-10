import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/domain/auth_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';

// Route-route yang dianggap "root" — tidak ada halaman sebelumnya di stack
const _rootRoutes = {
  AppRoutes.dashboard,
  AppRoutes.kelolaKendaraan,
  AppRoutes.kelolaDriver,
  AppRoutes.profil,
};

class AppShell extends ConsumerWidget {
  final Widget child;
  final String currentPath;
  const AppShell({super.key, required this.child, required this.currentPath});

  Future<bool> _onWillPop(BuildContext context) async {
    // Hanya intercept jika di root route
    if (!_rootRoutes.contains(currentPath)) return true;

    final keluar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar Aplikasi'),
        content: const Text('Apakah anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cancelled,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (keluar == true) {
      SystemNavigator.pop();
    }
    return false; // selalu false, keluar dihandle manual
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final role = user?.role ?? '';
    final isSuperadmin = role == 'superadmin';
    final hideFab = currentPath == AppRoutes.tambahPerjalanan;
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _onWillPop(context);
      },
      child: Scaffold(
      body: isDesktop
          ? Row(
              children: [
                _AppSidebar(currentPath: currentPath, isSuperadmin: isSuperadmin),
                Expanded(child: child),
              ],
            )
          : child,
      floatingActionButton: isDesktop || hideFab
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
      bottomNavigationBar: isDesktop
          ? null
          : (isSuperadmin
              ? _SuperadminNav(currentPath: currentPath)
              : _DefaultNav(currentPath: currentPath)),
      ),
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

// ── Sidebar Desktop/Web ───────────────────────────────────────────────────

class _SidebarItemData {
  final IconData icon;
  final String label;
  final String route;
  final List<String> activePaths;
  const _SidebarItemData({
    required this.icon,
    required this.label,
    required this.route,
    required this.activePaths,
  });
}

class _AppSidebar extends StatelessWidget {
  final String currentPath;
  final bool isSuperadmin;
  const _AppSidebar({required this.currentPath, required this.isSuperadmin});

  @override
  Widget build(BuildContext context) {
    final items = isSuperadmin
        ? const [
            _SidebarItemData(
              icon: Icons.home_rounded,
              label: 'Dashboard',
              route: AppRoutes.dashboard,
              activePaths: [AppRoutes.dashboard],
            ),
            _SidebarItemData(
              icon: Icons.directions_car_rounded,
              label: 'Kelola Kendaraan',
              route: AppRoutes.kelolaKendaraan,
              activePaths: [
                AppRoutes.kelolaKendaraan,
                AppRoutes.tambahKendaraan,
              ],
            ),
            _SidebarItemData(
              icon: Icons.person_add_rounded,
              label: 'Kelola Driver',
              route: AppRoutes.kelolaDriver,
              activePaths: [AppRoutes.kelolaDriver, AppRoutes.tambahDriver],
            ),
            _SidebarItemData(
              icon: Icons.person_outline_rounded,
              label: 'Profil',
              route: AppRoutes.profil,
              activePaths: [AppRoutes.profil],
            ),
          ]
        : const [
            _SidebarItemData(
              icon: Icons.home_rounded,
              label: 'Dashboard',
              route: AppRoutes.dashboard,
              activePaths: [AppRoutes.dashboard],
            ),
            _SidebarItemData(
              icon: Icons.person_outline_rounded,
              label: 'Profil',
              route: AppRoutes.profil,
              activePaths: [AppRoutes.profil],
            ),
          ];

    return Container(
      width: 240,
      color: AppColors.primary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Logo / Brand ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'LT',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'LTMS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Tombol Tambah Perjalanan ──────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.tambahPerjalanan),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Tambah Perjalanan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
            const SizedBox(height: 12),

            // ── Menu ──────────────────────────────────────────
            for (final item in items)
              _SidebarTile(
                icon: item.icon,
                label: item.label,
                active: item.activePaths.contains(currentPath),
                onTap: () => context.go(item.route),
              ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: active ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: active ? Colors.white : Colors.white.withValues(alpha: 0.65),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.65),
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}