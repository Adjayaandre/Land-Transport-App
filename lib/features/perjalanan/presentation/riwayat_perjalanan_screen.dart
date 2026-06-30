import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_colors.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/perjalanan_repository.dart';
import '../../dashboard/domain/dashboard_provider.dart';

final _riwayatProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.read(tripRepositoryProvider).fetchSemua(),
);

class RiwayatPerjalananScreen extends ConsumerWidget {
  const RiwayatPerjalananScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuperadmin = ref.watch(authProvider).user?.role == 'superadmin';
    final riwayatAsync = ref.watch(_riwayatProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Riwayat Perjalanan'),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(_riwayatProvider),
        child: riwayatAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => Center(
            child: Text('Gagal memuat riwayat: $e',
                style: AppTextColors.style(context, fontSize: 13)),
          ),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      'Belum ada perjalanan selesai',
                      style: AppTextColors.style(context, fontSize: 13),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final trip = list[i];
                return _RiwayatCard(
                  trip: trip,
                  isSuperadmin: isSuperadmin,
                  onEdit: () => _showEditDialog(context, ref, trip),
                  onDelete: () => _confirmDelete(context, ref, trip),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Map<String, dynamic> trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Perjalanan'),
        content: Text(
            'Yakin ingin menghapus perjalanan ${trip['nomor_polisi'] ?? ''} (${trip['titik_jemput']} → ${trip['titik_tujuan']})? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
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

  Future<void> _showEditDialog(
      BuildContext context, WidgetRef ref, Map<String, dynamic> trip) async {
    final picController = TextEditingController(text: trip['pic'] as String? ?? '');
    final jemputController = TextEditingController(text: trip['titik_jemput'] as String? ?? '');
    final tujuanController = TextEditingController(text: trip['titik_tujuan'] as String? ?? '');
    final deskripsiController = TextEditingController(text: trip['deskripsi'] as String? ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Perjalanan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: picController,
                decoration: const InputDecoration(labelText: 'PIC'),
              ),
              TextField(
                controller: jemputController,
                decoration: const InputDecoration(labelText: 'Titik Jemput'),
              ),
              TextField(
                controller: tujuanController,
                decoration: const InputDecoration(labelText: 'Titik Tujuan'),
              ),
              TextField(
                controller: deskripsiController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    try {
      await ref.read(tripRepositoryProvider).update(trip['id'] as String, {
        'pic': picController.text.trim(),
        'titik_jemput': jemputController.text.trim(),
        'titik_tujuan': tujuanController.text.trim(),
        'deskripsi': deskripsiController.text.trim(),
      });
      ref.invalidate(_riwayatProvider);
      ref.invalidate(perjalananTerbaruProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perjalanan berhasil diperbarui')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui: $e')),
        );
      }
    }
  }
}

class _RiwayatCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final bool isSuperadmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RiwayatCard({
    required this.trip,
    required this.isSuperadmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final penumpang = (trip['penumpang'] as List?)?.map((e) => e.toString()).toList() ?? const [];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ?? AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_car_rounded,
                    color: AppColors.completed, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  trip['nomor_polisi'] as String? ?? '-',
                  style: AppTextColors.style(context, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              if (isSuperadmin) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dari: ${trip['titik_jemput']} → Ke: ${trip['titik_tujuan']}',
            style: AppTextColors.style(context, fontSize: 13, color: context.adaptiveTextSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Tanggal: ${trip['tanggal']}',
            style: AppTextColors.style(context, fontSize: 12, color: context.adaptiveTextSecondary),
          ),
          if (trip['jarak'] != null)
            Text(
              'Jarak: ${(trip['jarak'] as num).toStringAsFixed(0)} KM',
              style: AppTextColors.style(context, fontSize: 12, color: context.adaptiveTextSecondary),
            ),
          if (trip['waktu_tiba'] != null)
            Text(
              'Waktu Selesai: ${trip['waktu_tiba']}',
              style: AppTextColors.style(context, fontSize: 12, color: context.adaptiveTextSecondary),
            ),
          if (penumpang.isNotEmpty)
            Text(
              'Penumpang: ${penumpang.join(', ')}',
              style: AppTextColors.style(context, fontSize: 12, color: context.adaptiveTextSecondary),
            ),
        ],
      ),
    );
  }
}