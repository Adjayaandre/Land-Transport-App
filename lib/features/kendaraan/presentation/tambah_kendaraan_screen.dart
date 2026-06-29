import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_text_colors.dart';
import '../domain/kendaraan_model.dart';
import '../domain/kendaraan_provider.dart';

class TambahKendaraanScreen extends ConsumerStatefulWidget {
  final String? kendaraanId;

  const TambahKendaraanScreen({super.key, this.kendaraanId});

  @override
  ConsumerState<TambahKendaraanScreen> createState() =>
      _TambahKendaraanScreenState();
}

class _TambahKendaraanScreenState extends ConsumerState<TambahKendaraanScreen> {
  final _formKey = GlobalKey<FormState>();

  final _merkController = TextEditingController();
  final _modelController = TextEditingController();
  final _tahunController = TextEditingController();
  final _nomorPlatController = TextEditingController();

  bool _isSaving = false;
  bool _loaded = false;

  bool get _isEdit => widget.kendaraanId != null;

  @override
  void dispose() {
    _merkController.dispose();
    _modelController.dispose();
    _tahunController.dispose();
    _nomorPlatController.dispose();
    super.dispose();
  }

  void _fillForm(KendaraanModel item) {
    _merkController.text = item.merk;
    _modelController.text = item.model;
    _tahunController.text = item.tahun;
    _nomorPlatController.text = item.nomorPlat;
  }

  void _hapusIsian() {
    _formKey.currentState?.reset();
    _merkController.clear();
    _modelController.clear();
    _tahunController.clear();
    _nomorPlatController.clear();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(kendaraanRepositoryProvider);
      if (_isEdit) {
        final existing = await repo.getById(widget.kendaraanId!);
        if (existing == null) throw StateError('Kendaraan tidak ditemukan');
        await repo.update(
          existing.copyWith(
            merk: _merkController.text.trim(),
            model: _modelController.text.trim(),
            tahun: _tahunController.text.trim(),
            nomorPlat: _nomorPlatController.text.trim(),
          ),
        );
      } else {
        await repo.create(
          tipe: 'Mobil',
          merk: _merkController.text.trim(),
          model: _modelController.text.trim(),
          tahun: _tahunController.text.trim(),
          nomorPlat: _nomorPlatController.text.trim(),
        );
      }

      ref.invalidate(kendaraanListProvider);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Kendaraan berhasil diperbarui' : 'Kendaraan berhasil disimpan',
          ),
        ),
      );
      context.goNamed(AppRoutes.kelolaKendaraanName);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan kendaraan')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit && !_loaded) {
      final asyncItem = ref.watch(kendaraanByIdProvider(widget.kendaraanId!));
      return asyncItem.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => Scaffold(
          appBar: AppBar(title: const Text('Edit Kendaraan')),
          body: Center(
            child: Text(
              'Kendaraan tidak ditemukan',
              style: AppTextColors.style(context),
            ),
          ),
        ),
        data: (item) {
          if (item == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Kendaraan')),
              body: Center(
                child: Text(
                  'Kendaraan tidak ditemukan',
                  style: AppTextColors.style(context),
                ),
              ),
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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRoutes.kelolaKendaraanName);
            }
          },
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
            Text(_isEdit ? 'Edit Kendaraan' : 'Tambah Kendaraan Baru'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Informasi Dasar Kendaraan'),
                    const SizedBox(height: 12),
                    _label('Tipe Kendaraan'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).dividerTheme.color ??
                              AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_car_rounded,
                            size: 18,
                            color: context.adaptiveTextSecondary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Mobil',
                            style: AppTextColors.style(
                              context,
                              fontSize: 14,
                              color: context.adaptiveTextSecondary,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 16,
                            color: context.adaptiveTextMuted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _label('Merk Kendaraan'),
                    _buildTextField(
                      controller: _merkController,
                      hint: 'Toyota',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Model'),
                              _buildTextField(
                                controller: _modelController,
                                hint: 'Hiace',
                                validator: (v) => v == null || v.trim().isEmpty
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
                              _label('Tahun Pembuatan'),
                              _buildTextField(
                                controller: _tahunController,
                                hint: '2022',
                                keyboardType: TextInputType.number,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Wajib diisi'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _sectionHeader('Identifikasi Kendaraan'),
                    const SizedBox(height: 12),
                    _label('Nomor Plat'),
                    _buildTextField(
                      controller: _nomorPlatController,
                      hint: 'BK 1234 XY',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              child: Column(
                children: [
                  if (!_isEdit)
                    Center(
                      child: TextButton(
                        onPressed: _isSaving ? null : _hapusIsian,
                        child: Text(
                          'Hapus Isian',
                          style: AppTextColors.style(
                            context,
                            fontSize: 14,
                            color: context.adaptiveText,
                          ),
                        ),
                      ),
                    ),
                  if (!_isEdit) const SizedBox(height: 8),
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
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Kendaraan'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) => Text(
        text,
        style: AppTextColors.style(
          context,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: AppTextColors.style(
            context,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
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
              color: Theme.of(context).dividerTheme.color ?? AppColors.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Theme.of(context).dividerTheme.color ?? AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.cancelled),
          ),
        ),
      );
}
