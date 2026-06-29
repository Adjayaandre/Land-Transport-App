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
    final statsAsync = ref.watch(dashboardStatsProvider);
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang,',
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                          ),
                          Text(
                            user?.displayName ?? 'Pengguna',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ],
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

                  // ── Active Trips Card ────────────────────────
                  listAsync.when(
                    loading: () => _ShimmerBox(height: 100),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (list) => _ActiveTripsCard(trips: list),
                  ),
                  const SizedBox(height: 12),

                  // ── Stat Cards (hijau) ───────────────────────
                  statsAsync.when(
                    loading: () => Row(children: [
                      Expanded(child: _ShimmerBox(height: 80)),
                      const SizedBox(width: 12),
                      Expanded(child: _ShimmerBox(height: 80)),
                    ]),
                    error: (_, __) => _errBox('Gagal memuat statistik'),
                    data: (s) => IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _GreenStatCard(
                              label: 'Completed Today',
                              value: '${s.perjalananHariIni}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _GreenStatCard(
                              label: 'Last Month',
                              subLabel: 'Total KM:',
                              value: '${s.totalPerjalanan}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Recent Activities ────────────────────────
                  Text(
                    'Riwayat Perjalanan',
                    style: AppTextColors.style(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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

// ── Active Trips Card ─────────────────────────────────────────────────────────

class _ActiveTripsCard extends StatelessWidget {
  final List<PerjalananSingkat> trips;
  const _ActiveTripsCard({required this.trips});

  @override
  Widget build(BuildContext context) {
    final ongoing = trips.where((p) => !p.dokumenLengkap).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ?? AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Trips',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          if (ongoing.isEmpty)
            Row(children: [
              const Icon(Icons.check_circle_outline, size: 16, color: AppColors.completed),
              const SizedBox(width: 6),
              Text(
                'Tidak ada perjalanan aktif',
                style: AppTextColors.style(context, fontSize: 13),
              ),
            ])
          else
            ...ongoing.take(2).map((trip) => _OngoingRow(trip: trip)),
        ],
      ),
    );
  }
}

class _OngoingRow extends StatelessWidget {
  final PerjalananSingkat trip;
  const _OngoingRow({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(color: AppColors.ongoing, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              'Ongoing Trip',
              style: AppTextColors.style(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'Incoming/Outgoing',
                  style: AppTextColors.style(context, fontSize: 10, color: context.adaptiveTextMuted),
                ),
                Text(
                  trip.nomorPolisi,
                  style: AppTextColors.style(context, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ]),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'Route',
                  style: AppTextColors.style(context, fontSize: 10, color: context.adaptiveTextMuted),
                ),
                Text(
                  '${trip.titikJemput} → ${trip.titikTujuan}',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextColors.style(context, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ]),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Green Stat Card ───────────────────────────────────────────────────────────

class _GreenStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subLabel;

  const _GreenStatCard({required this.label, required this.value, this.subLabel});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextColors.style(
              context,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF388E3C),
            ),
          ),
          const SizedBox(height: 4),
          if (subLabel != null)
            Text(
              subLabel!,
              style: AppTextColors.style(
                context,
                fontSize: 11,
                color: isDark ? Colors.white : const Color(0xFF388E3C),
              ),
            ),
          Text(
            value,
            style: AppTextColors.style(
              context,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1B5E20),
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
    final isCompleted = trip.dokumenLengkap;
    final circleColor = isCompleted ? const Color(0xFFE8F5E9) : const Color(0xFFFEF3C7);
    final iconColor = isCompleted ? AppColors.completed : AppColors.ongoing;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Ikon mobil dalam lingkaran
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
            child: Icon(Icons.directions_car_rounded, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.namaDriver,
                  style: AppTextColors.style(
                    context,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isCompleted ? 'Incoming' : 'Ongoing'} Trip. ${trip.nomorPolisi}',
                  style: AppTextColors.style(context, fontSize: 12, color: context.adaptiveTextSecondary),
                ),
              ],
            ),
          ),

          // Waktu + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 12,
                  color: isCompleted ? AppColors.completed : AppColors.ongoing,
                ),
                const SizedBox(width: 4),
                Text(
                  _timeAgo(trip.tanggal),
                  style: AppTextColors.style(context, fontSize: 11, color: context.adaptiveTextSecondary),
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(String raw) {
    try {
      final d = DateTime.parse(raw);
      final diff = DateTime.now().difference(d);
      if (diff.inDays > 0) return '${diff.inDays} days ago';
      if (diff.inHours > 0) return '${diff.inHours} hours ago';
      return '${diff.inMinutes} min ago';
    } catch (_) {
      return raw;
    }
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