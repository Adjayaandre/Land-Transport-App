import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_text_colors.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/vehicle_avatar.dart';
import '../domain/kendaraan_model.dart';
import '../domain/kendaraan_provider.dart';

class KelolaKendaraanScreen extends ConsumerStatefulWidget {
  const KelolaKendaraanScreen({super.key});

  @override
  ConsumerState<KelolaKendaraanScreen> createState() =>
      _KelolaKendaraanScreenState();
}

class _KelolaKendaraanScreenState extends ConsumerState<KelolaKendaraanScreen> {
  final _searchController = TextEditingController();
  bool? _filterAktif; // null = semua, true = available, false = unavailable
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(kendaraanListProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Kelola Kendaraan'),
      ),
      body: Column(
        children: [
          // ── Search + Filter + Tambah ───────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Cari kendaraan...',
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
                Row(
                  children: [
                    // Filter dropdown
                    OutlinedButton.icon(
                      onPressed: () => _showFilterSheet(context),
                      icon: const Icon(Icons.filter_list_rounded, size: 16),
                      label: Text(_filterAktif == null
                          ? 'Filter'
                          : _filterAktif!
                              ? 'Available'
                              : 'Unavailable'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        side: BorderSide(
                            color: _filterAktif != null
                                ? AppColors.primary
                                : Theme.of(context).dividerTheme.color ??
                                    AppColors.border),
                        foregroundColor: _filterAktif != null
                            ? AppColors.primary
                            : context.adaptiveTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context
                            .pushNamed(AppRoutes.tambahKendaraanName),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Tambah Kendaraan'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 42),
                        ),
                      ),
                    ),
                  ],
                ),
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
                child: Text('Gagal memuat data kendaraan',
                    style: AppTextColors.style(context)),
              ),
              data: (items) {
                final filtered = items.where((k) {
                  final matchQuery = _query.isEmpty ||
                      k.nomorPlat.toLowerCase().contains(_query) ||
                      k.merek.toLowerCase().contains(_query) ||
                      k.model.toLowerCase().contains(_query);
                  final matchFilter =
                      _filterAktif == null || k.aktif == _filterAktif;
                  return matchQuery && matchFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.directions_car_outlined,
                    message: items.isEmpty
                        ? 'Belum ada kendaraan.\nTap Tambah untuk menambahkan.'
                        : 'Tidak ada kendaraan yang sesuai filter.',
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async =>
                      ref.invalidate(kendaraanListProvider),
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _KendaraanCard(item: filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
            Text('Filter Status',
                style: AppTextColors.style(context,
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _filterTile('Semua', null),
            _filterTile('Available', true),
            _filterTile('Unavailable', false),
          ],
        ),
      ),
    );
  }

  Widget _filterTile(String label, bool? value) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        trailing: _filterAktif == value
            ? const Icon(Icons.check_rounded, color: AppColors.primary)
            : null,
        onTap: () {
          setState(() => _filterAktif = value);
          Navigator.pop(context);
        },
      );
}

class _KendaraanCard extends ConsumerWidget {
  final KendaraanModel item;
  const _KendaraanCard({required this.item});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kendaraan'),
        content: Text('Hapus ${item.nomorPlat} dari daftar?'),
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

    if (confirm == true && context.mounted) {
      await ref.read(kendaraanRepositoryProvider).delete(item.id);
      ref.invalidate(kendaraanListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kendaraan berhasil dihapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aktif = item.aktif;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = VehicleAvatar.iconColor(aktif);
    final statusBg = VehicleAvatar.bgColor(aktif, isDark: isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: aktif
              ? AppColors.completed.withValues(alpha: 0.4)
              : const Color(0xFFF59E0B).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ikon + nomor pol + edit/hapus
          Row(
            children: [
              VehicleAvatar(aktif: aktif),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No. Pol: ${item.nomorPlat}',
                  style: AppTextColors.style(context,
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                visualDensity: VisualDensity.compact,
                onPressed: () => context.pushNamed(
                  AppRoutes.tambahKendaraanName,
                  queryParameters: {'id': item.id},
                ),
                icon: Icon(Icons.edit_outlined,
                    color: context.adaptiveTextSecondary, size: 20),
              ),
              IconButton(
                tooltip: 'Hapus',
                visualDensity: VisualDensity.compact,
                onPressed: () => _confirmDelete(context, ref),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.cancelled, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Info rows
          _infoRow(context, '${item.merek} ${item.model}'),
          const SizedBox(height: 4),
          if (item.warna != null && item.warna!.isNotEmpty)
            _infoRow(context, 'Warna: ${item.warna}'),
          const SizedBox(height: 4),
          _infoRow(
            context,
            'Odometer Sekarang: ${item.odometerSekarang.toStringAsFixed(0)} KM',
          ),
          const SizedBox(height: 12),

          // Status badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                aktif ? 'TERSEDIA' : 'TIDAK TERSEDIA',
                style: AppTextColors.style(
                  context,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String text) => Text(
        text,
        style: AppTextColors.style(
          context,
          fontSize: 13,
          color: context.adaptiveTextSecondary,
        ),
      );
}