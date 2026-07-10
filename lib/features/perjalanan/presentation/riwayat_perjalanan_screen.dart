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
    final riwayatAsync = ref.watch(_riwayatProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Riwayat Perjalanan'),
        actions: [
          if (canExport)
            riwayatAsync.whenData((klips) {
              return _isExporting
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Export Excel',
                      icon: const Icon(Icons.table_chart_outlined,
                          color: Colors.white),
                      onPressed: () => _handleExport(klips),
                    );
            }).valueOrNull ??
                const SizedBox.shrink(),
        ],
      ),
      body: Column(
        children: [
          // ── Search + Filter ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(
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
              const SizedBox(width: 8),
              Stack(
                children: [
                  OutlinedButton(
                    onPressed: _showFilterSheet,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: EdgeInsets.zero,
                      side: BorderSide(
                        color: _hasFilter
                            ? AppColors.primary
                            : Theme.of(context).dividerTheme.color ??
                                AppColors.border,
                      ),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: _hasFilter
                          ? AppColors.primary
                          : context.adaptiveTextSecondary,
                    ),
                  ),
                  if (_hasFilter)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              if (_hasFilter) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _resetFilter,
                  child: Container(
                    width: 36,
                    height: 48,
                    alignment: Alignment.center,
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.cancelled),
                  ),
                ),
              ],
            ]),
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
                      onExportPdf: (trip, kendaraan) => _exportTripPdf(trip, kendaraan),
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
      builder: (ctx) => AlertDialog(
        title: const Text('Ekspor Excel'),
        content: const Text('Pilih cara ekspor file:'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download'),
            onPressed: () => Navigator.of(ctx, rootNavigator: true)
                .pop(ExportMode.download),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Bagikan'),
            onPressed: () => Navigator.of(ctx, rootNavigator: true)
                .pop(ExportMode.bagikan),
          ),
        ],
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
      builder: (ctx) => AlertDialog(
        title: const Text('Ekspor PDF'),
        content: const Text('Pilih cara ekspor file:'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download'),
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(ExportMode.download),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Bagikan'),
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(ExportMode.bagikan),
          ),
        ],
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
}

// ── Klip Card ─────────────────────────────────────────────────────────────────

class _KlipCard extends StatefulWidget {
  final Map<String, dynamic> klip;
  final bool isSuperadmin;
  final void Function(Map<String, dynamic>) onDeleteTrip;
  final void Function(Map<String, dynamic>) onEditTrip;
  final void Function(Map<String, dynamic>, Map<String, dynamic>?) onExportPdf;

  const _KlipCard({
    required this.klip,
    required this.isSuperadmin,
    required this.onDeleteTrip,
    required this.onEditTrip,
    required this.onExportPdf,
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
        isAktif ? AppColors.completed : AppColors.primary;
    final statusBg = isAktif
        ? AppColors.completed.withValues(alpha: 0.1)
        : AppColors.primary.withValues(alpha: 0.1);

    final dibuatPada = _fmt(klip['dibuat_pada'] as String?);
    final ditutupPada = _fmt(klip['ditutup_pada'] as String?);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAktif
              ? AppColors.completed.withValues(alpha: 0.4)
              : Theme.of(context).dividerTheme.color ?? AppColors.border,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
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
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: context.adaptiveTextSecondary,
                ),
              ]),
            ),
          ),
          if (_expanded) ...[
            Divider(
                height: 1,
                color: Theme.of(context).dividerTheme.color ??
                    AppColors.border),
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

class _TripItem extends StatelessWidget {
  final Map<String, dynamic> trip;
  final bool isSuperadmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onExportPdf;

  const _TripItem({
    required this.trip,
    required this.isSuperadmin,
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
            if (isSuperadmin) ...[
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
                  size: 16, color: AppColors.primary),
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