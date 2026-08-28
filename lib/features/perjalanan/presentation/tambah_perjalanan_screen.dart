import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_text_colors.dart';
import '../../../shared/signature_pad.dart';
import '../../../shared/foto_picker.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/perjalanan_repository.dart';
import '../domain/klip_provider.dart';
import '../../dashboard/domain/dashboard_provider.dart';

class TambahPerjalananScreen extends ConsumerStatefulWidget {
  const TambahPerjalananScreen({super.key});

  @override
  ConsumerState<TambahPerjalananScreen> createState() =>
      _TambahPerjalananScreenState();
}

class _TambahPerjalananScreenState
    extends ConsumerState<TambahPerjalananScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _picController = TextEditingController();
  final _kapalController = TextEditingController();
  final _titikJemputController = TextEditingController();
  final _titikTujuanController = TextEditingController();
  final _odometerAkhirController = TextEditingController();
  final _deskripsiController = TextEditingController();

  // State
  DateTime _tanggal = DateTime.now();
  TimeOfDay _waktuJemput = TimeOfDay.now();
  TimeOfDay _waktuSampai = TimeOfDay.now();

  // Kendaraan
  List<Map<String, dynamic>> _daftarKendaraan = [];
  String? _kendaraanId;
  double? _kendaraanOdometerSekarang;
  bool _odometerSamaWarning = false;
  bool _loadingKendaraan = true;

  // Klip
  String? _klipAktifId;
  bool _loadingKlip = false;

  // Signature
  final List<List<Offset?>> _sigDriverStrokes = [];
  final List<List<Offset?>> _sigPicStrokes = [];
  bool _scrollLocked = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchKendaraan();
  }

  Future<void> _fetchKendaraan() async {
    try {
      final data = await Supabase.instance.client
          .from('kendaraan')
          .select('id, nomor_polisi, merek, model, odometer_sekarang')
          .eq('aktif', true)
          .order('nomor_polisi');
      if (!mounted) return;
      setState(() {
        _daftarKendaraan = List<Map<String, dynamic>>.from(data);
        _loadingKendaraan = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingKendaraan = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar kendaraan: $e')),
      );
    }
  }

  @override
  void dispose() {
    _picController.dispose();
    _kapalController.dispose();
    _titikJemputController.dispose();
    _titikTujuanController.dispose();
    _odometerAkhirController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _pickTime(bool isJemput) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isJemput ? _waktuJemput : _waktuSampai,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isJemput) {
          _waktuJemput = picked;
        } else {
          _waktuSampai = picked;
        }
      });
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  void _hapusTandaTangan() {
    setState(() {
      _sigDriverStrokes.clear();
      _sigPicStrokes.clear();
    });
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /// Render strokes ke PNG bytes (400×200 px, background putih, tinta navy).
  Future<void> _fetchKlipAktif(String kendaraanId) async {
    setState(() => _loadingKlip = true);
    try {
      final klip = await ref
          .read(klipRepositoryProvider)
          .getKlipAktif(kendaraanId);
      if (mounted) setState(() => _klipAktifId = klip?.id);
    } finally {
      if (mounted) setState(() => _loadingKlip = false);
    }
  }

  Future<void> _handleBuatKlipBaru() async {
    final authUser = ref.read(authProvider).user;
    if (authUser == null || _kendaraanId == null) return;

    // Kalau ada klip aktif, tutup dulu
    if (_klipAktifId != null) {
      final ditutup = await _showTutupKlipDialog();
      if (!ditutup) return;
    }

    // Konfirmasi buat klip baru
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_road_rounded,
                    color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 18),
              Text(
                'Buat Klip Baru?',
                style: AppTextColors.style(ctx,
                    fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Klip perjalanan baru akan langsung dimulai saat ini dan siap diisi data perjalanan.',
                textAlign: TextAlign.center,
                style: AppTextColors.style(ctx,
                    fontSize: 13,
                    color: Theme.of(ctx).textTheme.bodySmall?.color,
                    height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: AppColors.border),
                      ),
                      onPressed: () =>
                          Navigator.of(ctx, rootNavigator: true).pop(false),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () =>
                          Navigator.of(ctx, rootNavigator: true).pop(true),
                      child: const Text('Buat'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final klip = await ref.read(klipRepositoryProvider).buatKlipBaru(
            idKendaraan: _kendaraanId!,
            dibuatOleh: authUser.id,
          );
      if (mounted) setState(() => _klipAktifId = klip.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Klip perjalanan baru berhasil dibuat')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat klip: $e')),
        );
      }
    }
  }

  Future<bool> _showTutupKlipDialog() async {
    Uint8List? fotoNotaBytes;
    Uint8List? fotoOdometerBytes;
    final odometerCtrl = TextEditingController(
      text: _kendaraanOdometerSekarang?.toStringAsFixed(0) ?? '',
    );
    bool uploading = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_clock_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tutup Klip Saat Ini',
                              style: AppTextColors.style(ctx,
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Lengkapi data berikut sebelum membuat klip baru',
                              style: AppTextColors.style(ctx,
                                  fontSize: 12,
                                  color:
                                      Theme.of(ctx).textTheme.bodySmall?.color),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppColors.border),

                // ── Body ──
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DialogSectionLabel(
                          icon: Icons.speed_rounded,
                          label: 'Odometer Terakhir',
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: odometerCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Masukkan odometer',
                            suffixText: 'KM',
                            filled: true,
                            fillColor: Theme.of(ctx)
                                .inputDecorationTheme
                                .fillColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            helperText: _kendaraanOdometerSekarang != null
                                ? 'Odometer sekarang: ${_kendaraanOdometerSekarang!.toStringAsFixed(0)} KM'
                                : null,
                            helperStyle: const TextStyle(fontSize: 11.5),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _DialogSectionLabel(
                          icon: Icons.camera_alt_rounded,
                          label: 'Foto Odometer',
                        ),
                        const SizedBox(height: 8),
                        FotoPicker(
                          fotoBytes: fotoOdometerBytes,
                          label: 'Foto panel odometer',
                          icon: Icons.speed_rounded,
                          onFotoSelected: (b) =>
                              setDialogState(() => fotoOdometerBytes = b),
                          onHapus: () =>
                              setDialogState(() => fotoOdometerBytes = null),
                        ),
                        const SizedBox(height: 20),
                        _DialogSectionLabel(
                          icon: Icons.receipt_long_rounded,
                          label: 'Foto Nota Bensin',
                        ),
                        const SizedBox(height: 8),
                        FotoPicker(
                          fotoBytes: fotoNotaBytes,
                          label: 'Foto nota pembelian bensin',
                          icon: Icons.receipt_long_outlined,
                          onFotoSelected: (b) =>
                              setDialogState(() => fotoNotaBytes = b),
                          onHapus: () =>
                              setDialogState(() => fotoNotaBytes = null),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                Divider(height: 1, color: AppColors.border),
                // ── Actions ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: AppColors.border),
                          ),
                          onPressed: uploading
                              ? null
                              : () => Navigator.of(ctx, rootNavigator: true)
                                  .pop(false),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: uploading
                              ? null
                              : () async {
                                  final odometer =
                                      double.tryParse(odometerCtrl.text.trim());
                                  if (odometer == null) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Odometer wajib diisi')));
                                    return;
                                  }
                                  if (_kendaraanOdometerSekarang != null &&
                                      odometer < _kendaraanOdometerSekarang!) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                        content: Text(
                                            'Odometer tidak boleh kurang dari ${_kendaraanOdometerSekarang!.toStringAsFixed(0)} KM')));
                                    return;
                                  }
                                  if (fotoOdometerBytes == null) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Foto odometer wajib diambil')));
                                    return;
                                  }
                                  if (fotoNotaBytes == null) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Foto nota bensin wajib diambil')));
                                    return;
                                  }
                                  setDialogState(() => uploading = true);
                                  try {
                                    await ref
                                        .read(klipRepositoryProvider)
                                        .tutupKlip(
                                          klipId: _klipAktifId!,
                                          odometerTutup: odometer,
                                          fotoNotaBytes: fotoNotaBytes!,
                                          fotoOdometerBytes: fotoOdometerBytes!,
                                        );
                                    // Update odometer kendaraan agar tersinkron
                                    await ref
                                        .read(tripRepositoryProvider)
                                        .updateOdometerKendaraan(
                                          _kendaraanId!,
                                          odometer,
                                        );
                                    if (mounted) {
                                      setState(() =>
                                          _kendaraanOdometerSekarang = odometer);
                                    }
                                    if (ctx.mounted) {
                                      Navigator.of(ctx, rootNavigator: true)
                                          .pop(true);
                                    }
                                  } catch (e) {
                                    setDialogState(() => uploading = false);
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                            content:
                                                Text('Gagal menutup klip: $e')),
                                      );
                                    }
                                  }
                                },
                          child: uploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Tutup Klip'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return result == true;
  }

  Future<Uint8List> _renderSignaturePng(List<List<Offset?>> strokes) async {
    const w = 400.0;
    const h = 200.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()..color = Colors.white,
    );

    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      final path = Path();
      var started = false;
      for (final point in stroke) {
        if (point == null) {
          started = false;
        } else if (!started) {
          path.moveTo(point.dx, point.dy);
          started = true;
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(w.toInt(), h.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Upload tanda tangan ke Storage dan insert ke tabel tanda_tangan.
  Future<void> _saveTandaTangan({
    required String perjalananId,
    required String jenis, // 'driver' atau 'pic'
    required List<List<Offset?>> strokes,
    required String namaPenanda,
  }) async {
    const bucket = 'tanda-tangan';
    final bytes = await _renderSignaturePng(strokes);
    final path = '$perjalananId/$jenis-${DateTime.now().millisecondsSinceEpoch}.png';

    await Supabase.instance.client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
        );

    final url = Supabase.instance.client.storage.from(bucket).getPublicUrl(path);

    await Supabase.instance.client.from('tanda_tangan').insert({
      'id_perjalanan': perjalananId,
      'jenis': jenis,
      'url_file': url,
      'path_file': path,
      'nama_penanda': namaPenanda,
      'ditanda_pada': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    final authUser = ref.read(authProvider).user;
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi login tidak valid.')),
      );
      return;
    }

    if (_kendaraanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kendaraan wajib dipilih.')),
      );
      return;
    }

    if (_klipAktifId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Buat klip perjalanan terlebih dahulu.')),
      );
      return;
    }

    final picDiisi = _picController.text.trim().isNotEmpty;

    if (_sigDriverStrokes.isEmpty ||
        (picDiisi && _sigPicStrokes.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(picDiisi
              ? 'Tanda tangan driver dan PIC wajib diisi.'
              : 'Tanda tangan driver wajib diisi.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final odometerRaw = _odometerAkhirController.text.trim();
      final input = PerjalananInput(
        driverId: authUser.id,
        kendaraanId: _kendaraanId!,
        tanggal: _tanggal,
        pic: _picController.text.trim(),
        namaKapal: _kapalController.text.trim(),
        waktuJemput: _combineDateTime(_tanggal, _waktuJemput),
        waktuTiba: _combineDateTime(_tanggal, _waktuSampai),
        titikJemput: _titikJemputController.text.trim(),
        titikTujuan: _titikTujuanController.text.trim(),
        odometerAkhir:
            odometerRaw.isEmpty ? null : double.tryParse(odometerRaw),
        deskripsi: _deskripsiController.text.trim(),
        idKlip: _klipAktifId,
      );

      final perjalananId = await ref.read(tripRepositoryProvider).create(input);

      // Simpan tanda tangan driver dan PIC ke Storage + tabel
      await _saveTandaTangan(
        perjalananId: perjalananId,
        jenis: 'driver',
        strokes: _sigDriverStrokes,
        namaPenanda: authUser.name,
      );
      if (picDiisi && _sigPicStrokes.isNotEmpty) {
        await _saveTandaTangan(
          perjalananId: perjalananId,
          jenis: 'pic',
          strokes: _sigPicStrokes,
          namaPenanda: _picController.text.trim(),
        );
      }

      if (input.odometerAkhir != null) {
        await ref.read(tripRepositoryProvider).updateOdometerKendaraan(
              _kendaraanId!,
              input.odometerAkhir!,
            );
      }
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(perjalananTerbaruProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perjalanan berhasil disimpan')),
      );
      context.go(AppRoutes.dashboard);
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan perjalanan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/logo_ltd.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Tambah Perjalanan Baru'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: _scrollLocked
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Tanggal Kegiatan ──────────────────────────
              _sectionLabel('Tanggal Kegiatan'),
              _buildTanggal(),
              const SizedBox(height: 16),

              // ── Kendaraan ─────────────────────────────────
              _sectionLabel('Kendaraan'),
              _buildKendaraanDropdown(),
              if (_kendaraanId != null) ...[
                const SizedBox(height: 10),
                _buildKlipStatus(),
              ],
              const SizedBox(height: 16),

              // ── PIC ───────────────────────────────────────
              _sectionLabel('Person In Charge (PIC)', optional: true),
              _buildTextField(
                controller: _picController,
                hint: 'Nama PIC (opsional)',
                prefixIcon: Icons.person_outline_rounded,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // ── Kapal (opsional) ──────────────────────────
              _sectionLabel('Kapal yang Dilayani ', optional: true),
              _buildTextField(
                controller: _kapalController,
                hint: '(Opsional) - Tidak wajib isi',
                prefixIcon: Icons.directions_boat_outlined,
              ),
              const SizedBox(height: 16),

              // ── Waktu & Titik Jemput ──────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Waktu Jemput'),
                        _buildTimePicker(isJemput: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Waktu Sampai'),
                        _buildTimePicker(isJemput: false),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _sectionLabel('Titik Jemput'),
              _buildTextField(
                controller: _titikJemputController,
                hint: 'Lokasi penjemputan',
                prefixIcon: Icons.location_on_outlined,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              _sectionLabel('Titik Tujuan'),
              _buildTextField(
                controller: _titikTujuanController,
                hint: 'Lokasi tujuan',
                prefixIcon: Icons.location_on_rounded,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // ── Odometer ──────────────────────────────────
              _sectionLabel('Odometer Akhir'),
              if (_kendaraanOdometerSekarang != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Odometer kendaraan saat ini: ${_kendaraanOdometerSekarang!.toStringAsFixed(0)} KM',
                    style: AppTextColors.style(context, fontSize: 12, color: context.adaptiveTextSecondary),
                  ),
                ),
              _buildTextField(
                controller: _odometerAkhirController,
                hint: 'KM akhir',
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final value = double.tryParse(v.trim());
                  final sama = value != null &&
                      _kendaraanOdometerSekarang != null &&
                      value == _kendaraanOdometerSekarang;
                  if (sama != _odometerSamaWarning) {
                    setState(() => _odometerSamaWarning = sama);
                  }
                },
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final value = double.tryParse(v.trim());
                  if (value == null) return 'Angka tidak valid';
                  if (_kendaraanOdometerSekarang != null &&
                      value < _kendaraanOdometerSekarang!) {
                    return 'Tidak boleh kurang dari odometer saat ini (${_kendaraanOdometerSekarang!.toStringAsFixed(0)} KM)';
                  }
                  return null;
                },
              ),
              if (_odometerSamaWarning)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Odometer sama dengan odometer sekarang. Pastikan ini benar (misalnya perjalanan dekat).',
                          style: AppTextColors.style(context,
                              fontSize: 11, color: const Color(0xFFF59E0B)),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // ── Deskripsi ─────────────────────────────────
              _sectionLabel('Deskripsi Kegiatan'),
              _buildTextField(
                controller: _deskripsiController,
                hint: 'Deskripsi kegiatan...',
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // ── Tanda Tangan Driver ───────────────────────
              _sectionLabel('Tanda Tangan Driver'),
              const SizedBox(height: 8),
              SignaturePad(
                strokes: _sigDriverStrokes,
                onDrawStart: () => setState(() => _scrollLocked = true),
                onDrawEnd: () => setState(() => _scrollLocked = false),
              ),
              const SizedBox(height: 16),

              // ── Tanda Tangan PIC (hanya jika PIC diisi) ───
              if (_picController.text.trim().isNotEmpty) ...[
                _sectionLabel('Tanda Tangan PIC'),
                const SizedBox(height: 8),
                SignaturePad(
                  strokes: _sigPicStrokes,
                  onDrawStart: () => setState(() => _scrollLocked = true),
                  onDrawEnd: () => setState(() => _scrollLocked = false),
                ),
                const SizedBox(height: 24),
              ],

              // ── Hapus Tanda Tangan ────────────────────────
              Center(
                child: TextButton(
                  onPressed: _hapusTandaTangan,
                  child: Text(
                    'Hapus Tanda Tangan',
                    style: AppTextColors.style(context, fontSize: 14, color: context.adaptiveText),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Tombol Simpan ─────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _simpan,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan & Mulai Perjalanan'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, {bool optional = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: RichText(
          text: TextSpan(
            text: text,
            style: AppTextColors.style(
              context,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            children: optional
                ? [
                    TextSpan(
                      text: '(Opsional)',
                      style: AppTextColors.style(
                        context,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.adaptiveText,
                      ),
                    ),
                  ]
                : [],
          ),
        ),
      );

  Widget _buildTanggal() => GestureDetector(
        onTap: _pickDate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(context).dividerTheme.color ?? AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 10),
              Text(
                _formatDate(_tanggal),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );

  Widget _buildTimePicker({required bool isJemput}) => GestureDetector(
        onTap: () => _pickTime(isJemput),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(context).dividerTheme.color ?? AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(isJemput ? _waktuJemput : _waktuSampai),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Icon(Icons.access_time_rounded,
                  size: 18, color: context.adaptiveTextSecondary),
            ],
          ),
        ),
      );

  Widget _buildKlipStatus() {
    if (_loadingKlip) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: Theme.of(context).dividerTheme.color ?? AppColors.border),
        ),
        child: const Row(children: [
          SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 10),
          Text('Memeriksa klip...', style: TextStyle(fontSize: 13)),
        ]),
      );
    }

    final hasKlip = _klipAktifId != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasKlip
            ? AppColors.completed.withValues(alpha: 0.08)
            : AppColors.cancelled.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasKlip
              ? AppColors.completed.withValues(alpha: 0.4)
              : AppColors.cancelled.withValues(alpha: 0.4),
        ),
      ),
      child: Row(children: [
        Icon(
          hasKlip ? Icons.folder_open_rounded : Icons.folder_off_outlined,
          size: 18,
          color: hasKlip ? AppColors.completed : AppColors.cancelled,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            hasKlip
                ? 'Klip perjalanan aktif'
                : 'Belum ada klip aktif untuk kendaraan ini',
            style: AppTextColors.style(
              context,
              fontSize: 13,
              color: hasKlip ? AppColors.completed : AppColors.cancelled,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: _handleBuatKlipBaru,
          style: TextButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            hasKlip ? 'Klip Baru' : 'Buat Klip',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: hasKlip ? AppColors.primary : AppColors.cancelled,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildKendaraanDropdown() {
    if (_loadingKendaraan) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).dividerTheme.color ?? AppColors.border,
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Memuat kendaraan...'),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _kendaraanId,
      isExpanded: true,
      validator: (v) => v == null ? 'Wajib dipilih' : null,
      style: AppTextColors.style(context, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Pilih kendaraan',
        prefixIcon: const Icon(Icons.directions_car_outlined, size: 20),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Theme.of(context).dividerTheme.color ?? AppColors.border,
            )),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Theme.of(context).dividerTheme.color ?? AppColors.border,
            )),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.cancelled)),
      ),
      items: _daftarKendaraan.map((k) {
        final aktif = k['aktif'] as bool? ?? true;
        final warna = k['warna'] as String?;
        final label = [
          k['nomor_polisi'],
          '(${[k['merek'], k['model']].where((e) => e != null && '$e'.isNotEmpty).join(' ')})',
          if (warna != null && warna.isNotEmpty) '· $warna',
        ].where((e) => e != null && '$e'.isNotEmpty).join(' ');
        final dotColor = aktif ? AppColors.completed : const Color(0xFFF59E0B);
        return DropdownMenuItem<String>(
          value: k['id'] as String,
          child: Row(children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
          ]),
        );
      }).toList(),
      onChanged: (value) async {
        setState(() {
          _kendaraanId = value;
          _klipAktifId = null;
          final selected = _daftarKendaraan.firstWhere(
            (k) => k['id'] == value,
            orElse: () => {},
          );
          _kendaraanOdometerSekarang =
              (selected['odometer_sekarang'] as num?)?.toDouble();
          // Isi otomatis field odometer akhir dengan odometer sekarang,
          // pengguna tetap bisa mengubahnya secara manual.
          if (_kendaraanOdometerSekarang != null) {
            _odometerAkhirController.text =
                _kendaraanOdometerSekarang!.toStringAsFixed(0);
            // Autofill selalu sama dengan odometer sekarang, jadi
            // tampilkan warning langsung (onChanged tidak terpicu saat autofill).
            _odometerSamaWarning = true;
          } else {
            _odometerSamaWarning = false;
          }
        });
        if (value != null) await _fetchKlipAktif(value);
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        onChanged: onChanged,
        textCapitalization: keyboardType == TextInputType.number
            ? TextCapitalization.none
            : TextCapitalization.characters,
        style: AppTextColors.style(context, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).dividerTheme.color ?? AppColors.border,
              )),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).dividerTheme.color ?? AppColors.border,
              )),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cancelled)),
        ),
      );
}

// ── Label section kecil untuk dialog (ikon + teks) ─────────────────────────
class _DialogSectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DialogSectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextColors.style(context,
              fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}