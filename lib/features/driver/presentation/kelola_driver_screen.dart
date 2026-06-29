import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_text_colors.dart';
import '../../../shared/empty_state.dart';
import '../domain/driver_model.dart';
import '../domain/driver_provider.dart';

class KelolaDriverScreen extends ConsumerWidget {
  const KelolaDriverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(driverListProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Kelola Driver'),
        actions: [
          TextButton.icon(
            onPressed: () => context.pushNamed(AppRoutes.tambahDriverName),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Tambah', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Gagal memuat data driver',
            style: AppTextColors.style(context),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.person_outline_rounded,
              message: 'Belum ada driver.\nTap Tambah untuk menambahkan.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(driverListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _DriverCard(item: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _DriverCard extends ConsumerWidget {
  final DriverModel item;
  const _DriverCard({required this.item});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Driver'),
        content: Text('Hapus ${item.nama} dari daftar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cancelled,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref.read(driverRepositoryProvider).delete(item.id);
      ref.invalidate(driverListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver berhasil dihapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ?? AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nama,
                  style: AppTextColors.style(
                    context,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.email,
                  style: AppTextColors.style(context, fontSize: 13, color: context.adaptiveTextSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: () => context.pushNamed(
              AppRoutes.tambahDriverName,
              queryParameters: {'id': item.id},
            ),
            icon: Icon(Icons.edit_outlined, color: context.adaptiveTextSecondary),
          ),
          IconButton(
            tooltip: 'Hapus',
            onPressed: () => _confirmDelete(context, ref),
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.cancelled),
          ),
        ],
      ),
    );
  }
}
