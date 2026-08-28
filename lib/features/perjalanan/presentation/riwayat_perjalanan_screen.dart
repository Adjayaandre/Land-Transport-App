import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/file_saver.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_text_colors.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/perjalanan_repository.dart';
import '../data/perjalanan_export_service.dart';
import '../data/perjalanan_pdf_service.dart';
import '../../dashboard/domain/dashboard_provider.dart';

final _riwayatProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.read(tripRepositoryProvider).fetchKlipDenganPerjalanan(),
);

class RiwayatPerjalananScreen extends ConsumerStatefulWidget {
  const RiwayatPerjalananScreen({super.key});

  @override
  ConsumerState<RiwayatPerjalananScreen> createState() =>
      _RiwayatPerjalananScreenState();
}

class _RiwayatPerjalananScreenState
    extends ConsumerState<RiwayatPerjalananScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _filterStatus; // null=semua, 'aktif', 'tutup'
  DateTimeRange? _filterTanggal;
  bool _isExporting = false;
  final Set<String> _selectedKlipIds = {};

  bool get _isSelecting => _selectedKlipIds.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedKlipIds.contains(id)) {
        _selectedKlipIds.remove(id);
      } else {
        _selectedKlipIds.add(id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedKlipIds.clear();
    });
  }

  Future<void> _confirmDeleteSelected(WidgetRef ref) async {
    final count = _selectedKlipIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Klip Terpilih'),
        content: Text(
            'Yakin ingin menghapus $count klip yang dipilih beserta semua '
            'perjalanan di dalamnya? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx, rootNavigator: true).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx, rootNavigator: true).pop(true),
            child:
                const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final futures = _selectedKlipIds.map((id) =>
          ref.read(tripRepositoryProvider).deleteKlip(id));
      await Future.wait(futures);
      
      _exitSelectionMode();
      ref.invalidate(_riwayatProvider);
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(perjalananTerbaruProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count klip berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus klip: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> klips) {
    return klips.where((k) {
      // Filter nomor polisi
      if (_query.isNotEmpty) {
        final kendaraan = k['kendaraan'] as Map<String, dynamic>?;
        final nomor =
            (kendaraan?['nomor_polisi'] as String? ?? '').toLowerCase();
        final merek = (kendaraan?['merek'] as String? ?? '').toLowerCase();
        final model = (kendaraan?['model'] as String? ?? '').toLowerCase();
        if (!nomor.contains(_query) &&
            !merek.contains(_query) &&
            !model.contains(_query)) return false;
      }

      // Filter status
      if (_filterStatus != null && k['status'] != _filterStatus) return false;

      // Filter tanggal
      if (_filterTanggal != null) {
        final raw = k['dibuat_pada'] as String?;
        if (raw == null) return false;
        final tgl = DateTime.tryParse(raw)?.toLocal();
        if (tgl == null) return false;
        final start = _filterTanggal!.start;
        final end = _filterTanggal!.end
            .add(const Duration(days: 1))
            .subtract(const Duration(seconds: 1));
        if (tgl.isBefore(start) || tgl.isAfter(end)) return false;
      }

      return true;
    }).toList();
  }

  bool get _hasFilter =>
      _query.isNotEmpty || _filterStatus != null || _filterTanggal != null;

  void _resetFilter() => setState(() {
        _query = '';
        _searchController.clear();
        _filterStatus = null;
        _filterTanggal = null;
      });

  Future<void> _showFilterSheet() async {
    String? tempStatus = _filterStatus;
    DateTimeRange? tempTanggal = _filterTanggal;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('Filter',
                    style: AppTextColors.style(context,
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setSheet(() {
                      tempStatus = null;
                      tempTanggal = null;
                    });
                  },
                  child: const Text('Reset'),
                ),
              ]),
              const SizedBox(height: 16),

              // Status klip
              Text('Status Klip',
                  style: AppTextColors.style(context,
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: [
                _statusChip(setSheet, null, 'Semua', tempStatus,
                    (v) => tempStatus = v),
                const SizedBox(width: 8),
                _statusChip(setSheet, 'aktif', 'Aktif', tempStatus,
                    (v) => tempStatus = v,
                    color: AppColors.completed),
                const SizedBox(width: 8),
                _statusChip(setSheet, 'tutup', 'Selesai', tempStatus,
                    (v) => tempStatus = v,
                    color: AppColors.primary),
              ]),
              const SizedBox(height: 20),

              // Rentang tanggal
              Text('Rentang Tanggal',
                  style: AppTextColors.style(context,
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: ctx,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDateRange: tempTanggal,
                    builder: (ctx2, child) {
                      final isDark2 =
                          Theme.of(ctx2).brightness == Brightness.dark;
                      return Theme(
                        data: Theme.of(ctx2).copyWith(
                          colorScheme: isDark2
                              ? const ColorScheme.dark(
                                  primary: AppColors.primaryLight,
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF1E2A3A),
                                  onSurface: Colors.white,
                                )
                              : const ColorScheme.light(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black87,
                                ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: isDark2
                                  ? AppColors.primaryLight
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setSheet(() => tempTanggal = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: tempTanggal != null
                          ? AppColors.primary
                          : Theme.of(context).dividerTheme.color ??
                              AppColors.border,
                    ),
                  ),
                  child: Row(children: [
                    Icon(Icons.date_range_rounded,
                        size: 18,
                        color: tempTanggal != null
                            ? AppColors.primary
                            : context.adaptiveTextSecondary),
                    const SizedBox(width: 10),
                    Text(
                      tempTanggal != null
                          ? '${_fmt(tempTanggal!.start)} – ${_fmt(tempTanggal!.end)}'
                          : 'Pilih rentang tanggal',
                      style: AppTextColors.style(
                        context,
                        fontSize: 13,
                        color: tempTanggal != null
                            ? AppColors.primary
                            : context.adaptiveTextSecondary,
                      ),
                    ),
                    if (tempTanggal != null) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setSheet(() => tempTanggal = null),
                        child: Icon(Icons.close_rounded,
                            size: 16,
                            color: context.adaptiveTextSecondary),
                      ),
                    ],
                  ]),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterStatus = tempStatus;
                      _filterTanggal = tempTanggal;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Terapkan Filter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(
    StateSetter setSheet,
    String? value,
    String label,
    String? current,
    void Function(String?) onSelect, {
    Color color = AppColors.primary,
  }) {
    final selected = current == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setSheet(() => onSelect(value)),
      selectedColor: color.withValues(alpha: 0.15),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? color : context.adaptiveTextSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
          color: selected
              ? color
              : (Theme.of(context).dividerTheme.color ?? AppColors.border)),
      backgroundColor: Theme.of(context).inputDecorationTheme.fillColor,
      showCheckmark: true,
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isSuperadmin = user?.role == 'superadmin';
    final isAdmin = user?.role == 'admin';
    final canExport = isSuperadmin || isAdmin;
    final canDelete = isSuperadmin || isAdmin;
    final riwayatAsync = ref.watch(_riwayatProvider);

    return Scaffold(
      appBar: AppBar(
        leading: _isSelecting
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                onPressed: _exitSelectionMode,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => context.pop(),
              ),
        title: Text(_isSelecting
            ? '${_selectedKlipIds.length} dipilih'
            : 'Riwayat Perjalanan'),
        actions: [
          if (_isSelecting)
            IconButton(
              tooltip: 'Hapus Klip Terpilih',
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              onPressed: () => _confirmDeleteSelected(ref),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Search + Filter ──────────────────────────────
          // ── Search + Filter + Export ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari nomor polisi / kendaraan...',
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
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (canExport) ...[
                  Expanded(
                    child: riwayatAsync.whenData((klips) {
                      return OutlinedButton.icon(
                        onPressed: _isExporting ? null : () => _handleExport(klips),
                        icon: _isExporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(Icons.table_chart_outlined, size: 18),
                        label: Text(
                            _isExporting ? 'Mengekspor...' : 'Export Excel'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          side: BorderSide(
                              color: Theme.of(context).dividerTheme.color ??
                                  AppColors.border),
                        ),
                      );
                    }).valueOrNull ??
                        const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFilterSheet,
                    icon: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: _hasFilter
                          ? AppColors.primary
                          : context.adaptiveTextSecondary,
                    ),
                    label: Text(
                      'Filter',
                      style: TextStyle(
                        color: _hasFilter
                            ? AppColors.primary
                            : context.adaptiveTextSecondary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      side: BorderSide(
                        color: _hasFilter
                            ? AppColors.primary
                            : Theme.of(context).dividerTheme.color ??
                                AppColors.border,
                      ),
                    ),
                  ),
                ),
                if (_hasFilter) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _resetFilter,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: AppColors.cancelled),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.cancelled),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── List ────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.invalidate(_riwayatProvider),
              child: riwayatAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, __) => Center(
                  child: Text('Gagal memuat riwayat: $e',
                      style: AppTextColors.style(context, fontSize: 13)),
                ),
                data: (klips) {
                  final filtered = _applyFilter(klips);
                  if (filtered.isEmpty) {
                    return ListView(children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Column(children: [
                          Icon(Icons.folder_off_outlined,
                              size: 48,
                              color: context.adaptiveTextMuted),
                          const SizedBox(height: 12),
                          Text(
                            _hasFilter
                                ? 'Tidak ada klip yang sesuai filter'
                                : 'Belum ada klip perjalanan',
                            style: AppTextColors.style(context,
                                fontSize: 13),
                          ),
                        ]),
                      ),
                    ]);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, i) => _KlipCard(
                      klip: filtered[i],
                      isSuperadmin: isSuperadmin,
                      canDelete: canDelete,
                      isSelected: _selectedKlipIds.contains(filtered[i]['id'] as String),
                      isSelecting: _isSelecting,
                      onLongPress: canDelete
                          ? () => _toggleSelection(filtered[i]['id'] as String)
                          : null,
                      onTap: () {
                        if (_isSelecting) {
                          _toggleSelection(filtered[i]['id'] as String);
                        }
                      },
                      onDeleteTrip: (trip) =>
                          _confirmDelete(context, ref, trip),
                      onEditTrip: (trip) async {
                        final updated = await context.push<bool>(
                          AppRoutes.editPerjalanan,
                          extra: trip,
                        );
                        if (updated == true)
                          ref.invalidate(_riwayatProvider);
                      },
                      onExportPdf: (trip, kendaraan) =>
                          _exportTripPdf(trip, kendaraan),
                      onExportKlipPdf: () =>
                          _exportKlipPdf(context, filtered[i]),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(List<Map<String, dynamic>> semua) async {
    // Pilih rentang tanggal dulu
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
      helpText: 'Pilih Rentang Tanggal Export',
      saveText: 'Export',
      builder: (ctx, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? const ColorScheme.dark(
                  primary: AppColors.primaryLight,
                  onPrimary: Colors.white,
                  surface: Color(0xFF1E2A3A),
                  onSurface: Colors.white,
                )
              : const ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black87,
                ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor:
                  isDark ? AppColors.primaryLight : AppColors.primary,
            ),
          ),
        ),
        child: child!,
      ),
    );

    if (range == null || !mounted) return;

    // Filter berdasarkan tanggal yang dipilih
    final end = range.end
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));
    final filtered = semua.where((k) {
      final raw = k['dibuat_pada'] as String?;
      if (raw == null) return false;
      final tgl = DateTime.tryParse(raw)?.toLocal();
      if (tgl == null) return false;
      return !tgl.isBefore(range.start) && !tgl.isAfter(end);
    }).toList();

    if (filtered.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tidak ada data perjalanan pada rentang tanggal ini')),
      );
      return;
    }

    // Pilih mode export
    if (!mounted) return;
    final mode = await showDialog<ExportMode>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _ExportModeDialog(
        icon: Icons.table_chart_rounded,
        accentColor: Color(0xFF16A34A),
        title: 'Ekspor ke Excel',
        subtitle: 'Rekap data perjalanan pada rentang tanggal yang dipilih',
      ),
    );

    if (mode == null || !mounted) return;

    setState(() => _isExporting = true);
    try {
      final path = await PerjalananExportService.exportToExcel(
        filtered,
        mode: mode,
      );
      if (mounted && mode == ExportMode.download) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rekap perjalanan berhasil didownload'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.green,
            action: (FileSaver.canOpenFile && path != null)
                ? SnackBarAction(
                    label: 'Buka',
                    textColor: Colors.white,
                    onPressed: () => FileSaver.openFile(path),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Map<String, dynamic> trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Perjalanan'),
        content: Text(
            'Yakin ingin menghapus perjalanan ${trip['nomor_polisi'] ?? ''} '
            '(${trip['titik_jemput']} → ${trip['titik_tujuan']})? '
            'Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx, rootNavigator: true).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx, rootNavigator: true).pop(true),
            child:
                const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(tripRepositoryProvider).delete(trip['id'] as String);
      ref.invalidate(_riwayatProvider);
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(perjalananTerbaruProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perjalanan berhasil dihapus')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }


  Future<void> _exportTripPdf(
      Map<String, dynamic> trip, Map<String, dynamic>? kendaraan) async {
    final mode = await showDialog<ExportMode>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _ExportModeDialog(
        icon: Icons.picture_as_pdf_rounded,
        accentColor: Color(0xFFDC2626),
        title: 'Ekspor PDF Perjalanan',
        subtitle: 'Dokumen lengkap satu perjalanan siap dicetak',
      ),
    );

    if (mode == null || !mounted) return;

    setState(() => _isExporting = true);
    try {
      final path = await PerjalananPdfService.exportTripPdf(
        trip,
        kendaraan,
        mode: mode,
      );
      if (mounted && mode == ExportMode.download) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Dokumen perjalanan berhasil didownload'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.green,
            action: (FileSaver.canOpenFile && path != null)
                ? SnackBarAction(
                    label: 'Buka',
                    textColor: Colors.white,
                    onPressed: () => FileSaver.openFile(path),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportKlipPdf(
      BuildContext context, Map<String, dynamic> klip) async {
    final perjalananList =
        (klip['perjalanan'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (perjalananList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Klip ini belum memiliki perjalanan')),
      );
      return;
    }

    final mode = await showDialog<ExportMode>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _ExportModeDialog(
        icon: Icons.picture_as_pdf_rounded,
        accentColor: Color(0xFFDC2626),
        title: 'Ekspor PDF Klip',
        subtitle: 'Laporan seluruh perjalanan dalam satu siklus BBM',
      ),
    );

    if (mode == null || !mounted) return;

    setState(() => _isExporting = true);
    try {
      final path = await PerjalananPdfService.exportKlipPdf(
        klip,
        mode: mode,
      );
      if (mounted && mode == ExportMode.download && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Laporan klip berhasil didownload'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.green,
            action: FileSaver.canOpenFile
                ? SnackBarAction(
                    label: 'Buka',
                    textColor: Colors.white,
                    onPressed: () => FileSaver.openFile(path),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export PDF klip: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}

// ── Klip Card ─────────────────────────────────────────────────────────────────

class _KlipCard extends StatefulWidget {
  final Map<String, dynamic> klip;
  final bool isSuperadmin;
  final bool isSelected;
  final bool isSelecting;
  final VoidCallback? onLongPress;
  final VoidCallback onTap;
  final void Function(Map<String, dynamic>) onDeleteTrip;
  final void Function(Map<String, dynamic>) onEditTrip;
  final void Function(Map<String, dynamic>, Map<String, dynamic>?) onExportPdf;
  final VoidCallback onExportKlipPdf;
  final bool canDelete;

  const _KlipCard({
    required this.klip,
    required this.isSuperadmin,
    required this.canDelete,
    required this.isSelected,
    required this.isSelecting,
    required this.onLongPress,
    required this.onTap,
    required this.onDeleteTrip,
    required this.onEditTrip,
    required this.onExportPdf,
    required this.onExportKlipPdf,
  });

  @override
  State<_KlipCard> createState() => _KlipCardState();
}

class _KlipCardState extends State<_KlipCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final klip = widget.klip;
    final isAktif = klip['status'] == 'aktif';
    final perjalanan =
        (klip['perjalanan'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final kendaraan = klip['kendaraan'] as Map<String, dynamic>?;
    final nomorPolisi = kendaraan?['nomor_polisi'] as String? ?? '-';
    final merekModel = [kendaraan?['merek'], kendaraan?['model']]
        .where((e) => e != null && '$e'.isNotEmpty)
        .join(' ');

    final statusColor =
        isAktif ? const Color(0xFFF59E0B) : Colors.green;
    final statusBg = isAktif
        ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
        : Colors.green.withValues(alpha: 0.1);

    final dibuatPada = _fmt(klip['dibuat_pada'] as String?);
    final ditutupPada = _fmt(klip['ditutup_pada'] as String?);

    return Container(
      decoration: BoxDecoration(
        color: widget.isSelected 
            ? AppColors.primary.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isSelected
              ? AppColors.primary
              : (isAktif
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                  : Theme.of(context).dividerTheme.color ?? AppColors.border),
          width: widget.isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onLongPress: widget.onLongPress,
            onTap: () {
              if (widget.isSelecting) {
                widget.onTap();
              } else {
                setState(() => _expanded = !_expanded);
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isAktif
                        ? Icons.folder_open_rounded
                        : Icons.folder_rounded,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(nomorPolisi,
                            style: AppTextColors.style(context,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        if (merekModel.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(merekModel,
                              style: AppTextColors.style(context,
                                  fontSize: 12,
                                  color: context.adaptiveTextSecondary)),
                        ],
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isAktif ? 'Aktif' : 'Selesai',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isAktif
                                ? 'Dimulai $dibuatPada'
                                : '$dibuatPada – $ditutupPada',
                            style: AppTextColors.style(context,
                                fontSize: 11,
                                color: context.adaptiveTextSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text(
                        '${perjalanan.length} perjalanan',
                        style: AppTextColors.style(context,
                            fontSize: 11,
                            color: context.adaptiveTextMuted),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.onExportKlipPdf,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded,
                        size: 18, color: Colors.green),
                  ),
                ),
                if (widget.isSelecting) ...[
                  const SizedBox(width: 6),
                  Icon(
                    widget.isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: widget.isSelected
                        ? AppColors.primary
                        : context.adaptiveTextSecondary,
                    size: 24,
                  ),
                ] else ...[
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: context.adaptiveTextSecondary,
                  ),
                ],
              ]),
            ),
          ),
          if (_expanded) ...[
            Divider(
                height: 1,
                color: Theme.of(context).dividerTheme.color ??
                    AppColors.border),

            // ── Foto Klip (odometer + nota bensin) ───────
            if (klip['foto_odometer_url'] != null ||
                klip['foto_nota_url'] != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bukti Penutupan Klip',
                      style: AppTextColors.style(context,
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (klip['foto_odometer_url'] != null)
                          Expanded(
                            child: _FotoKlip(
                              label: 'Odometer',
                              url: klip['foto_odometer_url'] as String,
                            ),
                          ),
                        if (klip['foto_odometer_url'] != null &&
                            klip['foto_nota_url'] != null)
                          const SizedBox(width: 10),
                        if (klip['foto_nota_url'] != null)
                          Expanded(
                            child: _FotoKlip(
                              label: 'Nota Bensin',
                              url: klip['foto_nota_url'] as String,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(
                        height: 1,
                        color: Theme.of(context).dividerTheme.color ??
                            AppColors.border),
                  ],
                ),
              ),

            if (perjalanan.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Belum ada perjalanan dalam klip ini',
                  style: AppTextColors.style(context,
                      fontSize: 12,
                      color: context.adaptiveTextSecondary),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                itemCount: perjalanan.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _TripItem(
                  trip: perjalanan[i],
                  isSuperadmin: widget.isSuperadmin,
                  canDelete: widget.canDelete,
                  onEdit: () => widget.onEditTrip(perjalanan[i]),
                  onDelete: () => widget.onDeleteTrip(perjalanan[i]),
                  onExportPdf: () => widget.onExportPdf(perjalanan[i], kendaraan),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _fmt(String? raw) {
    if (raw == null) return '-';
    try {
      final d = DateTime.parse(raw).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    } catch (_) {
      return raw;
    }
  }
}

// ── Trip Item ─────────────────────────────────────────────────────────────────

// ── Foto Klip ─────────────────────────────────────────────────────────────────

class _FotoKlip extends StatelessWidget {
  final String label;
  final String url;
  const _FotoKlip({required this.label, required this.url});

  void _showFullscreen(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (ctx, _, __) => _FotoFullscreen(url: url, label: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextColors.style(context,
              fontSize: 11, color: context.adaptiveTextMuted),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showFullscreen(context),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) => progress == null
                      ? child
                      : Container(
                          height: 110,
                          color:
                              Theme.of(context).inputDecorationTheme.fillColor,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                  errorBuilder: (ctx, _, __) => Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).inputDecorationTheme.fillColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: context.adaptiveTextMuted, size: 28),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.zoom_in_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FotoFullscreen extends StatefulWidget {
  final String url;
  final String label;
  const _FotoFullscreen({required this.url, required this.label});

  @override
  State<_FotoFullscreen> createState() => _FotoFullscreenState();
}

class _FotoFullscreenState extends State<_FotoFullscreen> {
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resetZoom() => _controller.value = Matrix4.identity();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).pop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(widget.label,
              style: const TextStyle(fontSize: 14, color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.zoom_out_map_rounded, color: Colors.white),
              tooltip: 'Reset zoom',
              onPressed: _resetZoom,
            ),
          ],
        ),
        body: Center(
          child: InteractiveViewer(
            transformationController: _controller,
            minScale: 0.5,
            maxScale: 5.0,
            child: Image.network(
              widget.url,
              fit: BoxFit.contain,
              loadingBuilder: (ctx, child, progress) => progress == null
                  ? child
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white)),
              errorBuilder: (ctx, _, __) => const Center(
                child: Icon(Icons.broken_image_outlined,
                    color: Colors.white54, size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Trip Item ─────────────────────────────────────────────────────────────────

class _TripItem extends StatelessWidget {
  final Map<String, dynamic> trip;
  final bool isSuperadmin;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onExportPdf;

  const _TripItem({
    required this.trip,
    required this.isSuperadmin,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    final penumpang =
        (trip['penumpang'] as List?)?.map((e) => e.toString()).toList() ??
            const [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              Theme.of(context).dividerTheme.color ?? AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                '${trip['titik_jemput']} → ${trip['titik_tujuan']}',
                style: AppTextColors.style(context,
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            if (canDelete) ...[
              GestureDetector(
                onTap: onEdit,
                child: Icon(Icons.edit_outlined,
                    size: 16, color: context.adaptiveTextSecondary),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline,
                    size: 16, color: AppColors.cancelled),
              ),
              const SizedBox(width: 12),
            ],
            GestureDetector(
              onTap: onExportPdf,
              child: const Icon(Icons.picture_as_pdf_outlined,
                  size: 16, color: Colors.green),
            ),
          ]),
          const SizedBox(height: 4),
          _row(context, 'Tanggal', trip['tanggal'] as String? ?? '-'),
          if (trip['waktu_tiba'] != null)
            _row(context, 'Waktu Tiba', trip['waktu_tiba'] as String),
          if (trip['jarak'] != null)
            _row(context, 'Jarak',
                '${(trip['jarak'] as num).toStringAsFixed(0)} KM'),
          if (trip['pic'] != null && '${trip['pic']}'.isNotEmpty)
            _row(context, 'PIC', trip['pic'] as String),
          if (penumpang.isNotEmpty)
            _row(context, 'Penumpang', penumpang.join(', ')),
          if (trip['url_ttd_driver'] != null || trip['url_ttd_pic'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (trip['url_ttd_driver'] != null)
                  Expanded(
                    child: _FotoKlip(
                      label: 'TTD Driver',
                      url: trip['url_ttd_driver'] as String,
                    ),
                  ),
                if (trip['url_ttd_driver'] != null &&
                    trip['url_ttd_pic'] != null)
                  const SizedBox(width: 10),
                if (trip['url_ttd_pic'] != null)
                  Expanded(
                    child: _FotoKlip(
                      label: 'TTD PIC',
                      url: trip['url_ttd_pic'] as String,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(label,
                  style: AppTextColors.style(context,
                      fontSize: 11, color: context.adaptiveTextMuted)),
            ),
            Expanded(
              child: Text(value,
                  style: AppTextColors.style(context,
                      fontSize: 11,
                      color: context.adaptiveTextSecondary)),
            ),
          ],
        ),
      );
}

/// Dialog pilihan mode ekspor (Download / Bagikan) dengan desain kartu besar
/// yang nyaman disentuh, dilengkapi ikon dan deskripsi singkat tiap opsi.
class _ExportModeDialog extends StatelessWidget {
  const _ExportModeDialog({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? context.adaptiveTextSecondary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
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
              // Header dengan ikon besar sesuai jenis file
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withValues(alpha: 0.9),
                      accentColor,
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
                      child: Icon(icon, color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Pilihan mode: dua kartu besar yang mudah disentuh
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Pilih cara menyimpan file',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: context.adaptiveTextSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    _ExportOptionTile(
                      icon: Icons.download_rounded,
                      color: accentColor,
                      title: 'Download',
                      subtitle: 'Simpan file ke perangkat ini',
                      isDark: isDark,
                      textColor: textColor,
                      onTap: () => Navigator.of(context, rootNavigator: true)
                          .pop(ExportMode.download),
                    ),
                    const SizedBox(height: 10),
                    _ExportOptionTile(
                      icon: Icons.ios_share_rounded,
                      color: accentColor,
                      title: 'Bagikan',
                      subtitle: 'Kirim langsung lewat WhatsApp, email, dll.',
                      isDark: isDark,
                      textColor: textColor,
                      onTap: () => Navigator.of(context, rootNavigator: true)
                          .pop(ExportMode.bagikan),
                    ),
                  ],
                ),
              ),

              // Tombol batal
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: context.adaptiveTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
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
}

/// Satu opsi ekspor berbentuk kartu besar dengan ikon, judul, dan deskripsi
/// singkat, agar pengguna mudah membedakan Download vs Bagikan.
class _ExportOptionTile extends StatelessWidget {
  const _ExportOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.adaptiveTextSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.adaptiveTextSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}