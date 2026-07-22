import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_text_colors.dart';
import '../../auth/domain/auth_provider.dart';
import '../domain/driver_model.dart';
import '../domain/driver_provider.dart';

class TambahPenggunaScreen extends ConsumerStatefulWidget {
  final String? driverId;

  const TambahPenggunaScreen({super.key, this.driverId});

  @override
  ConsumerState<TambahPenggunaScreen> createState() => _TambahPenggunaScreenState();
}

class _TambahPenggunaScreenState extends ConsumerState<TambahPenggunaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _konfirmasiController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureKonfirmasi = true;
  bool _isSaving = false;
  bool _loaded = false;
  String _selectedPeran = 'driver';

  bool get _isEdit => widget.driverId != null;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  void _fillForm(DriverModel item) {
    _namaController.text = item.nama;
    _emailController.text = item.email;
    _selectedPeran = item.peran;
  }

  void _hapusIsian() {
    _formKey.currentState?.reset();
    _namaController.clear();
    _emailController.clear();
    _passwordController.clear();
    _konfirmasiController.clear();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(driverRepositoryProvider);
      if (_isEdit) {
        await repo.update(
          id: widget.driverId!,
          nama: _namaController.text.trim(),
          email: _emailController.text.trim(),
          peran: _selectedPeran,
        );
      } else {
        await repo.create(
          nama: _namaController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          peran: _selectedPeran,
        );
      }

      ref.invalidate(driverListProvider);
      ref.read(authProvider.notifier).refreshProfile();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Pengguna berhasil diperbarui'
                : 'Akun pengguna berhasil dibuat. Pengguna dapat login dengan email dan password tersebut.',
          ),
        ),
      );
      context.goNamed(AppRoutes.kelolaPenggunaName);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mapAuthError(e.message))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan pengguna: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('already registered') ||
        lower.contains('already been registered') ||
        lower.contains('user already registered')) {
      return 'Email sudah terdaftar.';
    }
    if (lower.contains('email not confirmed') ||
        lower.contains('confirm email')) {
      return 'Akun pengguna perlu konfirmasi email. Hubungi admin atau nonaktifkan "Confirm email" di Supabase Auth.';
    }
    if (lower.contains('edge function') ||
        lower.contains('deploy edge function')) {
      return message;
    }
    if (lower.contains('forbidden') || lower.contains('superadmin')) {
      return 'Hanya superadmin yang dapat menambah pengguna.';
    }
    if (lower.contains('migrasi sql') ||
        lower.contains('profil driver gagal')) {
      return message;
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit && !_loaded) {
      final asyncItem = ref.watch(driverByIdProvider(widget.driverId!));
      return asyncItem.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => Scaffold(
          appBar: AppBar(title: const Text('Edit Pengguna')),
          body: Center(
            child: Text(
              'Pengguna tidak ditemukan',
              style: AppTextColors.style(context),
            ),
          ),
        ),
        data: (item) {
          if (item == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Pengguna')),
              body: Center(
                child: Text(
                  'Pengguna tidak ditemukan',
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
              context.goNamed(AppRoutes.kelolaPenggunaName);
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
                'LTD',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(_isEdit ? 'Edit Pengguna' : 'Tambah Akun Pengguna'),
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
                    _sectionHeader('Informasi Akun Pengguna'),
                    const SizedBox(height: 16),
                    _label('Nama Lengkap'),
                    _buildTextField(
                      controller: _namaController,
                      hint: 'Nama lengkap pengguna',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    _label('Email'),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'email@example.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v.trim())) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _label('Role / Jabatan'),
                    _buildRolePicker(),
                    if (!_isEdit) ...[
                      const SizedBox(height: 14),
                      _label('Password'),
                      _buildTextField(
                        controller: _passwordController,
                        hint: 'Minimal 6 karakter',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscure: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: context.adaptiveTextMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Wajib diisi';
                          if (v.length < 6) return 'Minimal 6 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _label('Konfirmasi Password'),
                      _buildTextField(
                        controller: _konfirmasiController,
                        hint: 'Ulangi password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscure: _obscureKonfirmasi,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureKonfirmasi
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: context.adaptiveTextMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscureKonfirmasi = !_obscureKonfirmasi,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Wajib diisi';
                          if (v != _passwordController.text) {
                            return 'Password tidak cocok';
                          }
                          return null;
                        },
                      ),
                    ],
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
                          : Text(_isEdit
                              ? 'Simpan Perubahan'
                              : 'Buat Akun Pengguna'),
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

  static const _roles = [
    ('driver', 'Driver', Icons.drive_eta_rounded, Color(0xFF1E3A8A)),
    ('admin', 'Admin', Icons.admin_panel_settings_outlined, Color(0xFF2563EB)),
    ('superadmin', 'Super Admin', Icons.security_rounded, Color(0xFF7C3AED)),
    ('karyawan', 'Karyawan', Icons.work_outline_rounded, Color(0xFF059669)),
  ];

  Widget _buildRolePicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _roles.map((r) {
        final (value, label, icon, color) = r;
        final selected = _selectedPeran == value;
        return GestureDetector(
          onTap: () => setState(() => _selectedPeran = value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.12)
                  : Theme.of(context).inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? color
                    : (Theme.of(context).dividerTheme.color ??
                        AppColors.border),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon,
                  size: 16,
                  color: selected ? color : context.adaptiveTextSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextColors.style(
                  context,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? color : context.adaptiveTextSecondary,
                ),
              ),
            ]),
          ),
        );
      }).toList(),
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
    IconData? prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    bool obscure = false,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        validator: validator,
        style: AppTextColors.style(context, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
          suffixIcon: suffixIcon,
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
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.cancelled),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.cancelled, width: 1.5),
          ),
        ),
      );
}