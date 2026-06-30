import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_colors.dart';
import '../data/perjalanan_repository.dart';
import '../../dashboard/domain/dashboard_provider.dart';

class EditPerjalananScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> trip;
  const EditPerjalananScreen({super.key, required this.trip});

  @override
  ConsumerState<EditPerjalananScreen> createState() => _EditPerjalananScreenState();
}

class _EditPerjalananScreenState extends ConsumerState<EditPerjalananScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _picController;
  late final TextEditingController _kapalController;
  late final TextEditingController _titikJemputController;
  late final TextEditingController _titikTujuanController;
  late final TextEditingController _odometerAkhirController;
  late final TextEditingController _deskripsiController;

  late DateTime _tanggal;
  late TimeOfDay _waktuJemput;
  late TimeOfDay _waktuTiba;

  List<Map<String, dynamic>> _daftarKendaraan = [];
  String? _kendaraanId;
  bool _loadingKendaraan = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.trip;
    _picController = TextEditingController(text: t['pic'] as String? ?? '');
    _kapalController = TextEditingController(text: t['nama_kapal'] as String? ?? '');
    _titikJemputController = TextEditingController(text: t['titik_jemput'] as String? ?? '');
    _titikTujuanController = TextEditingController(text: t['titik_tujuan'] as String? ?? '');
    _odometerAkhirController = TextEditingController(
      text: t['odometer_akhir'] != null ? '${t['odometer_akhir']}' : '',
    );
    _deskripsiController = TextEditingController(text: t['deskripsi'] as String? ?? '');

    _tanggal = DateTime.tryParse(t['tanggal'] as String? ?? '') ?? DateTime.now();
    _waktuJemput = _parseTime(t['waktu_jemput'] as String?);
    _waktuTiba = _parseTime(t['waktu_tiba'] as String?);
    _kendaraanId = t['id_kendaraan'] as String?;

    _fetchKendaraan();
  }

  TimeOfDay _parseTime(String? raw) {
    if (raw == null) return TimeOfDay.now();
    final parts = raw.split(':');
    if (parts.length < 2) return TimeOfDay.now();
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
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
      initialTime: isJemput ? _waktuJemput : _waktuTiba,
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
          _waktuTiba = picked;
        }
      });
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';

  String _formatTimeLabel(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String _formatTimeForDb(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_kendaraanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kendaraan wajib dipilih.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final odometerRaw = _odometerAkhirController.text.trim();
      final data = {
        'id_kendaraan': _kendaraanId,
        'tanggal':
            '${_tanggal.year}-${_tanggal.month.toString().padLeft(2, '0')}-${_tanggal.day.toString().padLeft(2, '0')}',
        'pic': _picController.text.trim(),
        if (_kapalController.text.trim().isNotEmpty)
          'nama_kapal': _kapalController.text.trim(),
        'waktu_jemput': _formatTimeForDb(_waktuJemput),
        'waktu_tiba': _formatTimeForDb(_waktuTiba),
        'titik_jemput': _titikJemputController.text.trim(),
        'titik_tujuan': _titikTujuanController.text.trim(),
        if (odometerRaw.isNotEmpty) 'odometer_akhir': double.tryParse(odometerRaw),
        'deskripsi': _deskripsiController.text.trim(),
      };

      await ref.read(tripRepositoryProvider).update(widget.trip['id'] as String, data);
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(perjalananTerbaruProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perjalanan berhasil diperbarui')),
      );
      context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Edit Perjalanan'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Tanggal Kegiatan'),
              _buildTanggal(),
              const SizedBox(height: 16),

              _sectionLabel('Kendaraan'),
              _buildKendaraanDropdown(),
              const SizedBox(height: 16),

              _sectionLabel('Person In Charge (PIC)'),
              _buildTextField(
                controller: _picController,
                hint: 'Nama PIC',
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              _sectionLabel('Kapal yang Dilayani ', optional: true),
              _buildTextField(
                controller: _kapalController,
                hint: '(Opsional) - Tidak wajib isi',
                prefixIcon: Icons.directions_boat_outlined,
              ),
              const SizedBox(height: 16),

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
                validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              _sectionLabel('Titik Tujuan'),
              _buildTextField(
                controller: _titikTujuanController,
                hint: 'Lokasi tujuan',
                prefixIcon: Icons.location_on_rounded,
                validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              _sectionLabel('Odometer Akhir'),
              _buildTextField(
                controller: _odometerAkhirController,
                hint: 'KM akhir',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              _sectionLabel('Deskripsi Kegiatan'),
              _buildTextField(
                controller: _deskripsiController,
                hint: 'Deskripsi kegiatan...',
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _simpan,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Simpan Perubahan'),
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
            style: AppTextColors.style(context, fontSize: 13, fontWeight: FontWeight.w600),
            children: optional
                ? [
                    TextSpan(
                      text: '(Opsional)',
                      style: AppTextColors.style(context, fontSize: 12, fontWeight: FontWeight.w500, color: context.adaptiveText),
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
            border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 10),
              Text(_formatDate(_tanggal), style: Theme.of(context).textTheme.bodyMedium),
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
            border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatTimeLabel(isJemput ? _waktuJemput : _waktuTiba), style: Theme.of(context).textTheme.bodyMedium),
              Icon(Icons.access_time_rounded, size: 18, color: context.adaptiveTextSecondary),
            ],
          ),
        ),
      );

  Widget _buildKendaraanDropdown() {
    if (_loadingKendaraan) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.border),
        ),
        child: const Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text('Memuat kendaraan...'),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _kendaraanId,
      isExpanded: true,
      validator: (v) => v == null ? 'Wajib dipilih' : null,
      style: AppTextColors.style(context, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Pilih kendaraan',
        prefixIcon: const Icon(Icons.directions_car_outlined, size: 20),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.cancelled)),
      ),
      items: _daftarKendaraan.map((k) {
        final label = [
          k['nomor_polisi'],
          if (k['merek'] != null || k['model'] != null)
            '(${[k['merek'], k['model']].where((e) => e != null && '$e'.isNotEmpty).join(' ')})',
        ].where((e) => e != null && '$e'.isNotEmpty).join(' ');
        return DropdownMenuItem<String>(
          value: k['id'] as String,
          child: Text(label, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) => setState(() => _kendaraanId = value),
    );
  }

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
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cancelled)),
        ),
      );
}