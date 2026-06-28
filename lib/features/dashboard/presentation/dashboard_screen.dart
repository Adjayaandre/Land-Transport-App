import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
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
      backgroundColor: AppColors.background,
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
                            user?.name ?? 'Pengguna',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    // Notifikasi
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                            child: const Center(
                              child: Text('1', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
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
                    data: (s) => Row(
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
                            label: 'Last 7 Days',
                            subLabel: 'Total KM:',
                            value: '${s.totalPerjalanan}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Recent Activities ────────────────────────
                  const Text(
                    'Recent Activities',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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

  Widget _errBox(String msg) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 18),
          const SizedBox(width: 8),
          Text(msg, style: TextStyle(color: Colors.red[700], fontSize: 13)),
        ]),
      );

  Widget _emptyBox() => Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(children: [
          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text('Belum ada perjalanan', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ]),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Trips',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          if (ongoing.isEmpty)
            Row(children: [
              const Icon(Icons.check_circle_outline, size: 16, color: AppColors.completed),
              const SizedBox(width: 6),
              Text('Tidak ada perjalanan aktif', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
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
            const Text('Ongoing Trip', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Incoming/Outgoing', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                Text(trip.nomorPolisi, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              ]),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Route', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                Text(
                  '${trip.titikJemput} → ${trip.titikTujuan}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF388E3C))),
          const SizedBox(height: 4),
          if (subLabel != null)
            Text(subLabel!, style: const TextStyle(fontSize: 11, color: Color(0xFF388E3C))),
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20)),
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
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isCompleted ? 'Incoming' : 'Ongoing'} Trip. ${trip.nomorPolisi}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                Text(_timeAgo(trip.tanggal), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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