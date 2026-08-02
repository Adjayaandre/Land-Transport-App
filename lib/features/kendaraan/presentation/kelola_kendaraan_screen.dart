import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_text_colors.dart';
import '../../../shared/app_nav_brand.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/vehicle_avatar.dart';
import '../../dashboard/domain/dashboard_provider.dart';
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
      builder: (_) => _DeleteConfirmDialog(
        count: count,
        itemLabel: 'kendaraan',
        infoText: 'Riwayat perjalanan yang menggunakan kendaraan ini tetap '
            'tersimpan (nopol tercatat di histori), hanya data kendaraannya '
            'yang dihapus.',
      ),
    );

    if (confirm == true && mounted) {
      try {
        final idsToDelete = Set<String>.from(_selectedIds);
        await ref
            .read(kendaraanListProvider.notifier)
            .deleteByIds(idsToDelete);

        _exitSelectionMode();
        ref.invalidate(kendaraanStatusProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$count kendaraan berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus kendaraan: $e')),
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
    final listAsync = ref.watch(kendaraanListProvider);

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
            : 'Kelola Kendaraan'),
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
                        onPressed: () =>
                            context.pushNamed(AppRoutes.tambahKendaraanName),
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
              loading: () => const Center(child: CircularProgressIndicator()),
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
                  onRefresh: () =>
                      ref.read(kendaraanListProvider.notifier).reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _KendaraanCard(
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
  final bool isSelected;
  final bool isSelecting;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const _KendaraanCard({
    required this.item,
    required this.isSelected,
    required this.isSelecting,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aktif = item.aktif;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = VehicleAvatar.iconColor(aktif);
    final statusBg = VehicleAvatar.bgColor(aktif, isDark: isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: onLongPress,
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : statusBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (aktif
                      ? AppColors.completed.withValues(alpha: 0.4)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.4)),
              width: isSelected ? 2 : 1,
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
                        AppRoutes.tambahKendaraanName,
                        queryParameters: {'id': item.id},
                      ),
                      icon: Icon(Icons.edit_outlined,
                          color: context.adaptiveTextSecondary, size: 20),
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
        ),
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

/// Dialog konfirmasi hapus dengan desain yang tegas dan sengaja diberi
/// sedikit friksi (tombol hapus terkunci beberapa detik) agar pengguna
/// benar-benar sadar sebelum menekan konfirmasi.
class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog({
    required this.count,
    required this.itemLabel,
    required this.infoText,
  });

  final int count;
  final String itemLabel;
  final String infoText;

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
    final label =
        count > 1 ? '$count ${widget.itemLabel}' : '1 ${widget.itemLabel}';

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
                      'Hapus $label?',
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
                      'Data yang dihapus tidak dapat dikembalikan. '
                      'Tindakan ini bersifat permanen.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Theme.of(context).textTheme.bodyLarge?.color ??
                            context.adaptiveTextSecondary,
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
                              widget.infoText,
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
                            color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color ??
                                context.adaptiveTextSecondary,
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