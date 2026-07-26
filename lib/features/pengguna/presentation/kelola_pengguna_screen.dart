import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_text_colors.dart';
import '../../../shared/app_nav_brand.dart';
import '../../../shared/empty_state.dart';
import '../domain/driver_model.dart';
import '../domain/driver_provider.dart';

const _roles = ['driver', 'admin', 'superadmin', 'karyawan'];

const _roleColors = {
  'superadmin': Color(0xFF7C3AED),
  'admin': Color(0xFF2563EB),
  'driver': AppColors.primary,
  'karyawan': Color(0xFF059669),
};

class KelolaPenggunaScreen extends ConsumerStatefulWidget {
  const KelolaPenggunaScreen({super.key});

  @override
  ConsumerState<KelolaPenggunaScreen> createState() =>
      _KelolaPenggunaScreenState();
}

class _KelolaPenggunaScreenState extends ConsumerState<KelolaPenggunaScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _filterPeran; // null = semua
  final Set<String> _selectedIds = {};

  bool get _isSelecting => _selectedIds.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _confirmDeleteSelected() async {
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteConfirmDialog(count: count),
    );

    if (confirm == true && mounted) {
      try {
        final client = Supabase.instance.client;

        // Hapus akun Supabase Auth + baris tabel pengguna untuk tiap ID terpilih.
        // Aman dilakukan walau sudah punya riwayat perjalanan, karena FK
        // id_driver/dibuat_oleh di tabel perjalanan sudah ON DELETE SET NULL,
        // dan nama driver tetap tersimpan lewat kolom snapshot.
        for (final id in _selectedIds) {
          try {
            final response = await client.functions.invoke(
              'delete-user',
              body: {'user_id': id},
            );
            if (response.status != 200) {
              throw Exception(response.data?['error']?.toString() ??
                  'Gagal hapus akun auth');
            }
          } catch (e) {
            debugPrint('Gagal hapus akun auth untuk $id: $e');
          }
        }
        final futures = _selectedIds
            .map((id) => ref.read(driverRepositoryProvider).delete(id));
        await Future.wait(futures);

        _exitSelectionMode();
        ref.invalidate(driverListProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$count pengguna berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus pengguna: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(driverListProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 78,
        leadingWidth: 64,
        leading: _isSelecting
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                onPressed: _exitSelectionMode,
              )
            : const AppNavBrandLeading(),
        title: Text(_isSelecting
            ? '${_selectedIds.length} dipilih'
            : 'Kelola Pengguna'),
        actions: [
          if (_isSelecting)
            IconButton(
              tooltip: 'Hapus Terpilih',
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.cancelled),
              onPressed: _confirmDeleteSelected,
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Search + Filter + Tambah ───────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Cari pengguna...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Theme.of(context).dividerTheme.color ??
                                AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  OutlinedButton.icon(
                    onPressed: () => _showFilterSheet(context),
                    icon: const Icon(Icons.filter_list_rounded, size: 16),
                    label: Text(_filterPeran == null
                        ? 'Filter Role'
                        : _roleName(_filterPeran!)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      side: BorderSide(
                          color: _filterPeran != null
                              ? AppColors.primary
                              : Theme.of(context).dividerTheme.color ??
                                  AppColors.border),
                      foregroundColor: _filterPeran != null
                          ? AppColors.primary
                          : context.adaptiveTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.pushNamed(AppRoutes.tambahPenggunaName),
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text('Tambah Pengguna'),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 42)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── List ──────────────────────────────────────────
          Expanded(
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Gagal memuat data pengguna',
                    style: AppTextColors.style(context)),
              ),
              data: (items) {
                final filtered = items.where((d) {
                  final matchQuery = _query.isEmpty ||
                      d.nama.toLowerCase().contains(_query) ||
                      d.email.toLowerCase().contains(_query);
                  final matchRole =
                      _filterPeran == null || d.peran == _filterPeran;
                  return matchQuery && matchRole;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.person_outline_rounded,
                    message: items.isEmpty
                        ? 'Belum ada pengguna.\nTap Tambah untuk menambahkan.'
                        : 'Tidak ada pengguna yang sesuai filter.',
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.invalidate(driverListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _DriverCard(
                        item: item,
                        isSelected: _selectedIds.contains(item.id),
                        isSelecting: _isSelecting,
                        onLongPress: () => _toggleSelection(item.id),
                        onTap: () {
                          if (_isSelecting) {
                            _toggleSelection(item.id);
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _roleName(String role) {
    switch (role) {
      case 'superadmin':
        return 'Superadmin';
      case 'admin':
        return 'Admin';
      case 'driver':
        return 'Driver';
      case 'karyawan':
        return 'Karyawan';
      default:
        return role;
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Role',
                style: AppTextColors.style(context,
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _filterTile(context, 'Semua', null),
            ..._roles.map((r) => _filterTile(context, _roleName(r), r)),
          ],
        ),
      ),
    );
  }

  Widget _filterTile(BuildContext context, String label, String? value) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: value != null
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _roleColors[value] ?? AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : const Icon(Icons.people_outline_rounded, size: 18),
        title: Text(label),
        trailing: _filterPeran == value
            ? const Icon(Icons.check_rounded, color: AppColors.primary)
            : null,
        onTap: () {
          setState(() => _filterPeran = value);
          Navigator.pop(context);
        },
      );
}

class _DriverCard extends ConsumerWidget {
  final DriverModel item;
  final bool isSelected;
  final bool isSelecting;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const _DriverCard({
    required this.item,
    required this.isSelected,
    required this.isSelecting,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleColor = _roleColors[item.peran] ?? AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: onLongPress,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (Theme.of(context).dividerTheme.color ?? AppColors.border),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar dengan inisial
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    item.nama.isNotEmpty ? item.nama[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nama,
                      style: AppTextColors.style(context,
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.peran.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: roleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelecting)
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected
                      ? AppColors.primary
                      : context.adaptiveTextSecondary,
                  size: 24,
                )
              else
                IconButton(
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => context.pushNamed(
                    AppRoutes.tambahPenggunaName,
                    queryParameters: {'id': item.id},
                  ),
                  icon: Icon(Icons.edit_outlined,
                      color: context.adaptiveTextSecondary, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog konfirmasi hapus dengan desain yang tegas dan sengaja diberi
/// sedikit friksi (tombol hapus terkunci beberapa detik) agar pengguna
/// benar-benar sadar sebelum menekan konfirmasi.
class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog({required this.count});

  final int count;

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  static const _lockSeconds = 3;
  int _secondsLeft = _lockSeconds;
  Timer? _timer;

  bool get _isUnlocked => _secondsLeft <= 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) timer.cancel();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.count;
    final labelPengguna = count > 1 ? '$count pengguna' : '1 pengguna';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header merah dengan ikon peringatan besar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.cancelled.withValues(alpha: 0.95),
                      AppColors.cancelled,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Hapus $labelPengguna?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Isi peringatan
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Akun yang dihapus tidak dapat digunakan lagi untuk '
                      'masuk ke aplikasi. Tindakan ini bersifat permanen '
                      'dan tidak dapat dibatalkan.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Theme.of(context).textTheme.bodyLarge?.color ?? context.adaptiveTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Riwayat perjalanan tetap tersimpan (nama '
                              'tercatat di histori), hanya akun login-nya '
                              'yang dihapus.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color: context.adaptiveTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tombol aksi
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context,
                                rootNavigator: true)
                            .pop(false),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: context.adaptiveTextSecondary
                                .withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color ?? context.adaptiveTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isUnlocked
                            ? () => Navigator.of(context,
                                    rootNavigator: true)
                                .pop(true)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cancelled,
                          disabledBackgroundColor:
                              AppColors.cancelled.withValues(alpha: 0.4),
                          foregroundColor: Colors.white,
                          disabledForegroundColor:
                              Colors.white.withValues(alpha: 0.85),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isUnlocked
                              ? Row(
                                  key: const ValueKey('unlocked'),
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.delete_forever_rounded,
                                        size: 18),
                                    SizedBox(width: 6),
                                    Text('Ya, Hapus',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700)),
                                  ],
                                )
                              : Row(
                                  key: const ValueKey('locked'),
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation(
                                                Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Tunggu ${_secondsLeft}s',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}