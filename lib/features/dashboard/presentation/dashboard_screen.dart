import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../auth/domain/auth_provider.dart';
import '../domain/dashboard_provider.dart';
import '../domain/dashboard_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final listAsync = ref.watch(perjalananTerbaruProvider);

    void refresh() {
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(perjalananTerbaruProvider);
    }

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header biru ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.primary,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  bottom: 20,
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'LTMS',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Pengaturan
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.pengaturan),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration:   BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.00),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Welcome Card (teal) ───────────────────────
                  _WelcomeCard(nama: user?.displayName ?? 'Pengguna'),
                  const SizedBox(height: 16),

                  // ── Status Kendaraan ──────────────────────────
                  Text(
                    'Status Kendaraan',
                    style: AppTextColors.style(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Consumer(
                    builder: (context, ref, _) {
                      final kendaraanAsync = ref.watch(kendaraanStatusProvider);
                      return kendaraanAsync.when(
                        loading: () => _ShimmerBox(height: 80),
                        error: (_, __) => _errBox('Gagal memuat status kendaraan'),
                        data: (list) {
                          if (list.isEmpty) {
                            return _emptyBox();
                          }
                          return SizedBox(
                            height: 90,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: list.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (context, i) => _KendaraanStatusCard(kendaraan: list[i]),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Recent Activities ────────────────────────
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.riwayatPerjalanan),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Riwayat Perjalanan Selesai',
                          style: AppTextColors.style(
                            context,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(children: [
                          Text(
                            'Lihat semua',
                            style: AppTextColors.style(
                              context,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  listAsync.when(
                    loading: () => Column(
                      children: List.generate(3, (_) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ShimmerBox(height: 64),
                      )),
                    ),
                    error: (_, __) => _errBox('Gagal memuat perjalanan'),
                    data: (list) => list.isEmpty
                        ? _emptyBox()
                        : Column(children: list.map((p) => _ActivityItem(trip: p)).toList()),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      );
  }

  static Widget _errBox(String msg) => Builder(
        builder: (context) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Row(children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 18),
            const SizedBox(width: 8),
            Text(
              msg,
              style: AppTextColors.style(context, fontSize: 13, color: context.adaptiveText),
            ),
          ]),
        ),
      );

  static Widget _emptyBox() => Builder(
        builder: (context) => Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          alignment: Alignment.center,
          child: Column(children: [
            Icon(Icons.inbox_rounded, size: 48, color: context.adaptiveTextMuted),
            const SizedBox(height: 10),
            Text(
              'Belum ada perjalanan',
              style: AppTextColors.style(context, fontSize: 13, color: context.adaptiveText),
            ),
          ]),
        ),
      );
}

class _WelcomeCard extends StatelessWidget {
  final String nama;
  const _WelcomeCard({required this.nama});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F9B8E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14B8A6).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.alt_route_rounded,
              size: 90,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat Datang,',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$nama!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KendaraanStatusCard extends StatelessWidget {
  final Map<String, dynamic> kendaraan;
  const _KendaraanStatusCard({required this.kendaraan});

  @override
  Widget build(BuildContext context) {
    final aktif = kendaraan['aktif'] as bool? ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = aktif
        ? (isDark ? const Color(0xFF1B4332) : const Color(0xFFE8F5E9))
        : (isDark ? const Color(0xFF4A3B0F) : const Color(0xFFFEF3C7));
    final textColor = aktif
        ? (isDark ? Colors.white : const Color(0xFF388E3C))
        : (isDark ? Colors.white : const Color(0xFF92660B));
    final dotColor = aktif ? AppColors.completed : const Color(0xFFF59E0B);

    final merekModel = [kendaraan['merek'], kendaraan['model']]
        .where((e) => e != null && '$e'.isNotEmpty)
        .join(' ');

    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              aktif ? 'Tersedia' : 'Tidak Tersedia',
              style: AppTextColors.style(
                context,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            kendaraan['nomor_polisi'] as String? ?? '-',
            style: AppTextColors.style(
              context,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          if (merekModel.isNotEmpty)
            Text(
              merekModel,
              overflow: TextOverflow.ellipsis,
              style: AppTextColors.style(
                context,
                fontSize: 11,
                color: textColor,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Activity Item ─────────────────────────────────────────────────────────────

class _ActivityItem extends StatelessWidget {
  final PerjalananSingkat trip;
  const _ActivityItem({required this.trip});

  @override
  Widget build(BuildContext context) {
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
                  trip.nomorPolisi,
                  style: AppTextColors.style(context, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Row(children: [
                const Icon(Icons.check_circle, size: 14, color: AppColors.completed),
                const SizedBox(width: 4),
                Text(
                  'Completed',
                  style: AppTextColors.style(context, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.completed),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dari: ${trip.titikJemput} → Ke: ${trip.titikTujuan}',
            style: AppTextColors.style(context, fontSize: 13, color: context.adaptiveTextSecondary),
          ),
          const SizedBox(height: 4),
          if (trip.jarak != null)
            Text(
              'Jarak: ${trip.jarak!.toStringAsFixed(0)} KM',
              style: AppTextColors.style(context, fontSize: 12, color: context.adaptiveTextSecondary),
            ),
          if (trip.waktuTiba != null)
            Text(
              'Waktu Selesai: ${trip.waktuTiba}',
              style: AppTextColors.style(context, fontSize: 12, color: context.adaptiveTextSecondary),
            ),
          if (trip.penumpang.isNotEmpty)
            Text(
              'Penumpang: ${trip.penumpang.join(', ')}',
              style: AppTextColors.style(context, fontSize: 12, color: context.adaptiveTextSecondary),
            ),
        ],
      ),
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final double height;
  const _ShimmerBox({required this.height});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.3, end: 0.9).animate(_c);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _a,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
        ),
      );
}