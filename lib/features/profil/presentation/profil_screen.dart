import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_colors.dart';
import '../../auth/domain/auth_provider.dart';

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.1),
                            border: Border.all(color: AppColors.primary, width: 2.5),
                          ),
                          child: const Icon(Icons.person_rounded, size: 50, color: AppColors.primary),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _peranLabel(user?.role),
                          style: AppTextColors.style(context, fontSize: 13, color: context.adaptiveTextSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.displayName ?? 'Pengguna',
                          style: AppTextColors.style(context, fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi Pribadi',
                          style: AppTextColors.style(
                            context,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.adaptiveTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(label: 'Email', value: user?.email ?? '-'),
                        const Divider(height: 24),
                        _InfoRow(label: 'Role', value: _peranLabel(user?.role)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _peranLabel(String? r) => switch (r) {
        'superadmin' => 'Superadmin',
        'admin' => 'Administrator',
        'driver' => 'Driver',
        'karyawan' => 'Karyawan',
        _ => '-',
      };
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextColors.style(context, fontSize: 14, color: context.adaptiveTextSecondary)),
        Text(
          value,
          style: AppTextColors.style(context, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
