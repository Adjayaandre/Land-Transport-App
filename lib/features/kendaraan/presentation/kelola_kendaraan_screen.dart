import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_text_colors.dart';
import '../../../shared/empty_state.dart';
import '../domain/kendaraan_model.dart';
import '../domain/kendaraan_provider.dart';

class KelolaKendaraanScreen extends ConsumerWidget {
  const KelolaKendaraanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(kendaraanListProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Kelola Kendaraan'),
        actions: [
          TextButton.icon(
            onPressed: () => context.pushNamed(AppRoutes.tambahKendaraanName),
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
            'Gagal memuat data kendaraan',
            style: AppTextColors.style(context),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.directions_car_outlined,
              message: 'Belum ada kendaraan.\nTap Tambah untuk menambahkan.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(kendaraanListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _KendaraanCard(item: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _KendaraanCard extends ConsumerWidget {
  final KendaraanModel item;
  const _KendaraanCard({required this.item});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kendaraan'),
        content: Text('Hapus ${item.nomorPlat} dari daftar?'),
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
      await ref.read(kendaraanRepositoryProvider).delete(item.id);
      ref.invalidate(kendaraanListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kendaraan berhasil dihapus')),
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
            child: const Icon(Icons.directions_car_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nomorPlat,
                  style: AppTextColors.style(
                    context,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.merk} ${item.model} · ${item.tahun}',
                  style: AppTextColors.style(context, fontSize: 13, color: context.adaptiveTextSecondary),
                ),
                Text(
                  item.tipe,
                  style: AppTextColors.style(context, fontSize: 12, color: context.adaptiveTextMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: () => context.pushNamed(
              AppRoutes.tambahKendaraanName,
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
