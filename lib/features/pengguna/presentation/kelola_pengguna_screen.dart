import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_text_colors.dart';
import '../../../shared/empty_state.dart';
import '../domain/driver_model.dart';
import '../domain/driver_provider.dart';

const _roles = ['driver', 'admin', 'superadmin', 'karyawan'];

const _roleColors = {
  'superadmin': Color(0xFF7C3AED),
  'admin':      Color(0xFF2563EB),
  'driver':     AppColors.primary,
  'karyawan':   Color(0xFF059669),
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
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pengguna Terpilih'),
        content: Text('Yakin ingin menghapus $count pengguna dari daftar? '
            'Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cancelled,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final futures = _selectedIds.map((id) =>
            ref.read(driverRepositoryProvider).delete(id));
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
        leading: _isSelecting
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                onPressed: _exitSelectionMode,
              )
            : null,
        title: Text(_isSelecting
            ? '${_selectedIds.length} dipilih'
            : 'Kelola Pengguna'),
        actions: [
          if (_isSelecting)
            IconButton(
              tooltip: 'Hapus Terpilih',
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.cancelled),
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
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
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
      case 'superadmin': return 'Superadmin';
      case 'admin':      return 'Admin';
      case 'driver':     return 'Driver';
      case 'karyawan':   return 'Karyawan';
      default:           return role;
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
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : (Theme.of(context).dividerTheme.color ?? AppColors.border),
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
                    item.nama.isNotEmpty
                        ? item.nama[0].toUpperCase()
                        : '?',
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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