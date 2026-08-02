import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_text_colors.dart';
import '../../dashboard/domain/dashboard_provider.dart';
import '../domain/kendaraan_model.dart';
import '../domain/kendaraan_provider.dart';

class TambahKendaraanScreen extends ConsumerStatefulWidget {
  final String? kendaraanId;
  const TambahKendaraanScreen({super.key, this.kendaraanId});

  @override
  ConsumerState<TambahKendaraanScreen> createState() =>
      _TambahKendaraanScreenState();
}

class _TambahKendaraanScreenState
    extends ConsumerState<TambahKendaraanScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomorPlatController = TextEditingController();
  final _merekController = TextEditingController();
  final _modelController = TextEditingController();
  final _warnaController = TextEditingController();
  final _odometerController = TextEditingController();
  final _keteranganController = TextEditingController();

  bool _aktif = true;
  bool _isSaving = false;
  bool _loaded = false;

  bool get _isEdit => widget.kendaraanId != null;

  @override
  void dispose() {
    _nomorPlatController.dispose();
    _merekController.dispose();
    _modelController.dispose();
    _warnaController.dispose();
    _odometerController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  void _fillForm(KendaraanModel item) {
    _nomorPlatController.text = item.nomorPlat;
    _merekController.text = item.merek;
    _modelController.text = item.model;
    _warnaController.text = item.warna ?? '';
    _odometerController.text = item.odometerSekarang > 0
        ? item.odometerSekarang.toStringAsFixed(0)
        : '';
    _keteranganController.text = item.keterangan ?? '';
    _aktif = item.aktif;
  }

  void _hapusIsian() {
    _formKey.currentState?.reset();
    _nomorPlatController.clear();
    _merekController.clear();
    _modelController.clear();
    _warnaController.clear();
    _odometerController.clear();
    _keteranganController.clear();
    setState(() => _aktif = true);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(kendaraanRepositoryProvider);
      final odometer =
          double.tryParse(_odometerController.text.trim()) ?? 0;

      if (_isEdit) {
        final existing = await repo.getById(widget.kendaraanId!);
        if (existing == null) throw StateError('Kendaraan tidak ditemukan');
        await repo.update(
          existing.copyWith(
            nomorPlat: _nomorPlatController.text.trim(),
            merek: _merekController.text.trim(),
            model: _modelController.text.trim(),
            warna: _warnaController.text.trim().isEmpty
                ? null
                : _warnaController.text.trim(),
            odometerSekarang: odometer,
            aktif: _aktif,
            keterangan: _keteranganController.text.trim().isEmpty
                ? null
                : _keteranganController.text.trim(),
          ),
        );
      } else {
        await repo.create(
          nomorPlat: _nomorPlatController.text.trim(),
          merek: _merekController.text.trim(),
          model: _modelController.text.trim(),
          warna: _warnaController.text.trim().isEmpty
              ? null
              : _warnaController.text.trim(),
          odometerSekarang: odometer,
          aktif: _aktif,
          keterangan: _keteranganController.text.trim().isEmpty
              ? null
              : _keteranganController.text.trim(),
        );
      }

      ref.invalidate(kendaraanStatusProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit
              ? 'Kendaraan berhasil diperbarui'
              : 'Kendaraan berhasil disimpan'),
        ),
      );
      context.goNamed(AppRoutes.kelolaKendaraanName);
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
    if (_isEdit && !_loaded) {
      final asyncItem =
          ref.watch(kendaraanByIdProvider(widget.kendaraanId!));
      return asyncItem.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) => Scaffold(
          appBar: AppBar(title: const Text('Edit Kendaraan')),
          body: Center(
              child: Text('Kendaraan tidak ditemukan',
                  style: AppTextColors.style(context))),
        ),
        data: (item) {
          if (item == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Kendaraan')),
              body: Center(
                  child: Text('Kendaraan tidak ditemukan',
                      style: AppTextColors.style(context))),
            );
          }
          if (!_loaded) {
            _fillForm(item);
            _loaded = true;
          }
          return _buildForm(context);
        },
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.goNamed(AppRoutes.kelolaKendaraanName),
        ),
        title: Row(children: [
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
          Text(_isEdit ? 'Edit Kendaraan' : 'Tambah Kendaraan Baru'),
        ]),
      ),
      body: Form(
        key: _formKey,
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Identifikasi Kendaraan'),
                  const SizedBox(height: 12),

                  _label('Nomor Polisi'),
                  _buildTextField(
                    controller: _nomorPlatController,
                    hint: 'BK 1234 XY',
                    capitalization: TextCapitalization.characters,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Merek'),
                          _buildTextField(
                            controller: _merekController,
                            hint: 'Toyota',
                            capitalization: TextCapitalization.words,
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Wajib diisi'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Model'),
                          _buildTextField(
                            controller: _modelController,
                            hint: 'Hiace',
                            capitalization: TextCapitalization.words,
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Wajib diisi'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),

                  _label('Warna (Opsional)'),
                  _buildTextField(
                    controller: _warnaController,
                    hint: 'Putih',
                    capitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 20),

                  _sectionHeader('Odometer & Status'),
                  const SizedBox(height: 12),

                  _label('Odometer Sekarang (KM)'),
                  _buildTextField(
                    controller: _odometerController,
                    hint: '0',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),

                  _label('Status Kendaraan'),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _aktif = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _aktif
                                ? AppColors.completed.withValues(alpha: 0.12)
                                : Theme.of(context)
                                    .inputDecorationTheme
                                    .fillColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _aktif
                                  ? AppColors.completed
                                  : Theme.of(context).dividerTheme.color ??
                                      AppColors.border,
                              width: _aktif ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text('Available',
                                style: AppTextColors.style(
                                  context,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _aktif
                                      ? AppColors.completed
                                      : context.adaptiveTextSecondary,
                                )),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _aktif = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_aktif
                                ? const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.12)
                                : Theme.of(context)
                                    .inputDecorationTheme
                                    .fillColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !_aktif
                                  ? const Color(0xFFF59E0B)
                                  : Theme.of(context).dividerTheme.color ??
                                      AppColors.border,
                              width: !_aktif ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text('Unavailable',
                                style: AppTextColors.style(
                                  context,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: !_aktif
                                      ? const Color(0xFFF59E0B)
                                      : context.adaptiveTextSecondary,
                                )),
                          ),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),

                  _label('Keterangan (Opsional)'),
                  _buildTextField(
                    controller: _keteranganController,
                    hint: 'Catatan tambahan...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom actions
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            child: Column(children: [
              if (!_isEdit) ...[
                Center(
                  child: TextButton(
                    onPressed: _isSaving ? null : _hapusIsian,
                    child: Text('Hapus Isian',
                        style: AppTextColors.style(context,
                            fontSize: 14, color: context.adaptiveText)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
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
                              strokeWidth: 2, color: Colors.white))
                      : Text(_isEdit
                          ? 'Simpan Perubahan'
                          : 'Simpan Kendaraan'),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _sectionHeader(String text) => Text(text,
      style: AppTextColors.style(context,
          fontSize: 15, fontWeight: FontWeight.w700));

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: AppTextColors.style(context,
                fontSize: 13, fontWeight: FontWeight.w600)),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        maxLines: maxLines,
        validator: validator,
        style: AppTextColors.style(context, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: Theme.of(context).dividerTheme.color ??
                      AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: Theme.of(context).dividerTheme.color ??
                      AppColors.border)),
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