import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_text_colors.dart';
import '../../../shared/signature_pad.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/trip_repository.dart';
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

  // Signature
  final List<List<Offset?>> _sigDriverStrokes = [];
  final List<List<Offset?>> _sigPicStrokes = [];
  bool _scrollLocked = false;
  bool _isSaving = false;

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

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    final authUser = ref.read(authProvider).user;
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi login tidak valid.')),
      );
      return;
    }

    if (_sigDriverStrokes.isEmpty || _sigPicStrokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanda tangan driver dan PIC wajib diisi.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final odometerRaw = _odometerAkhirController.text.trim();
      final input = PerjalananInput(
        driverId: authUser.id,
        tanggal: _tanggal,
        pic: _picController.text.trim(),
        namaKapal: _kapalController.text.trim(),
        waktuJemput: _combineDateTime(_tanggal, _waktuJemput),
        waktuSampai: _combineDateTime(_tanggal, _waktuSampai),
        titikJemput: _titikJemputController.text.trim(),
        titikTujuan: _titikTujuanController.text.trim(),
        odometerAkhir:
            odometerRaw.isEmpty ? null : double.tryParse(odometerRaw),
        deskripsi: _deskripsiController.text.trim(),
        dokumenLengkap: false,
      );

      await ref.read(tripRepositoryProvider).create(input);
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'LTMS',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
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

              // ── PIC ───────────────────────────────────────
              _sectionLabel('Person In Charge (PIC)'),
              _buildTextField(
                controller: _picController,
                hint: 'Nama PIC',
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
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
              _buildTextField(
                controller: _odometerAkhirController,
                hint: 'KM akhir',
                keyboardType: TextInputType.number,
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

              // ── Tanda Tangan PIC ──────────────────────────
              _sectionLabel('Tanda Tangan PIC'),
              const SizedBox(height: 8),
              SignaturePad(
                strokes: _sigPicStrokes,
                onDrawStart: () => setState(() => _scrollLocked = true),
                onDrawEnd: () => setState(() => _scrollLocked = false),
              ),
              const SizedBox(height: 24),

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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
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
