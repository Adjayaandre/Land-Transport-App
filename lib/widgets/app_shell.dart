import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/domain/auth_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  void _close() {
    setState(() => _open = false);
    _ctrl.reverse();
  }

  void _goto(String route) {
    _close();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) context.go(route);
    });
  }

  // Tentukan index tab aktif berdasarkan path
  int _currentIndex(String path) {
    if (path == AppRoutes.dashboard) return 0;
    if (path == AppRoutes.riwayat) return 1;
    if (path == AppRoutes.cari) return 3;
    if (path == AppRoutes.profil) return 4;
    return 0;
  }

  void _onTabTap(int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        context.go(AppRoutes.riwayat);
      case 3:
        context.go(AppRoutes.cari);
      case 4:
        context.go(AppRoutes.profil);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'admin' || user?.role == 'superadmin';
    final currentPath = GoRouterState.of(context).uri.path;
    final currentIndex = _currentIndex(currentPath);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _ctrl,
            color: Colors.white,
          ),
          onPressed: _toggle,
        ),
        title: Text(
          _pageTitle(currentPath),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: const [],
      ),

      // ── Bottom Navigation Bar ──────────────────────────────
      bottomNavigationBar: _BottomNav(
        currentIndex: currentIndex,
        onTap: _onTabTap,
      ),

      // ── FAB Tengah ─────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppRoutes.tambahPerjalanan),
        backgroundColor: AppColors.primary,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      body: Stack(
        children: [
          widget.child,

          // Overlay gelap saat sidebar terbuka
          if (_open)
            FadeTransition(
              opacity: _fadeAnim,
              child: GestureDetector(
                onTap: _close,
                child: Container(color: Colors.black54),
              ),
            ),

          // Sidebar
          SlideTransition(
            position: _slideAnim,
            child: _Sidebar(
              user: user,
              isAdmin: isAdmin,
              currentPath: currentPath,
              onNavigate: _goto,
              onClose: _close,
            ),
          ),
        ],
      ),
    );
  }

  String _pageTitle(String path) {
    return switch (path) {
      AppRoutes.dashboard => 'Dashboard',
      AppRoutes.tambahPerjalanan => 'Tambah Perjalanan',
      AppRoutes.tambahKendaraan => 'Tambah Kendaraan',
      AppRoutes.tambahDriver => 'Tambah Driver',
      AppRoutes.riwayat => 'Riwayat',
      AppRoutes.cari => 'Cari Perjalanan',
      AppRoutes.profil => 'Profil',
      _ => 'LTMS',
    };
  }
}

// ── Bottom Navigation Bar ────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

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
          _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, currentIndex: currentIndex, onTap: onTap),
          _NavItem(icon: Icons.access_time_rounded, label: 'Riwayat', index: 1, currentIndex: currentIndex, onTap: onTap),
          const SizedBox(width: 56), // ruang untuk FAB
          _NavItem(icon: Icons.search_rounded, label: 'Cari', index: 3, currentIndex: currentIndex, onTap: onTap),
          _NavItem(icon: Icons.person_outline_rounded, label: 'Profil', index: 4, currentIndex: currentIndex, onTap: onTap),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: active ? Colors.white : Colors.white.withValues(alpha: 0.5)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? Colors.white : Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sidebar ──────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final dynamic user;
  final bool isAdmin;
  final String currentPath;
  final void Function(String) onNavigate;
  final VoidCallback onClose;

  const _Sidebar({
    required this.user,
    required this.isAdmin,
    required this.currentPath,
    required this.onNavigate,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(4, 0)),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  const _SidebarSection(label: 'MENU UTAMA'),
                  _SidebarItem(icon: Icons.dashboard_rounded, label: 'Dashboard', route: AppRoutes.dashboard, currentPath: currentPath, onTap: onNavigate),
                  _SidebarItem(icon: Icons.add_road_rounded, label: 'Tambah Perjalanan', route: AppRoutes.tambahPerjalanan, currentPath: currentPath, onTap: onNavigate),
                  if (isAdmin) ...[
                    const SizedBox(height: 8),
                    const _SidebarSection(label: 'MASTER DATA'),
                    _SidebarItem(icon: Icons.directions_car_rounded, label: 'Tambah Kendaraan', route: AppRoutes.tambahKendaraan, currentPath: currentPath, onTap: onNavigate),
                    _SidebarItem(icon: Icons.person_add_rounded, label: 'Tambah Driver', route: AppRoutes.tambahDriver, currentPath: currentPath, onTap: onNavigate),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 12),
              child: Center(child: Text('LTMS v1.0.0', style: TextStyle(fontSize: 11, color: Colors.grey[400]))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Pengguna',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A2E)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _peranLabel(user?.role),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _peranLabel(String? r) => switch (r) {
        'admin' => 'Administrator',
        'supervisor`' => 'Superadmin',
        'driver' => 'Driver',
        'karyawan' => 'Karyawan',
        _ => '-',
      };
}

class _SidebarSection extends StatelessWidget {
  final String label;
  const _SidebarSection({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey[400], letterSpacing: 0.8)),
      );
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentPath;
  final void Function(String) onTap;

  const _SidebarItem({required this.icon, required this.label, required this.route, required this.currentPath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = currentPath == route;
    return GestureDetector(
      onTap: () => onTap(route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: active ? AppColors.primary : Colors.grey[500]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? AppColors.primary : const Color(0xFF374151))),
          if (active) ...[const Spacer(), Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))],
        ]),
      ),
    );
  }
}