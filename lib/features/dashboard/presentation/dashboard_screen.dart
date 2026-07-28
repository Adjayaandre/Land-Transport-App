import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../shared/vehicle_avatar.dart';
import '../../auth/domain/auth_provider.dart';
import '../domain/dashboard_provider.dart';
import '../domain/dashboard_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final listAsync = ref.watch(perjalananTerbaruProvider);
    final greeting = _greetingForHour(DateTime.now().hour);

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
            // ── Header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, Color(0xFF1E4FA8)],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20,
                  right: 16,
                  bottom: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/logo_ltd.png',
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Land Transport Digital',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.pengaturan),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.settings_outlined,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            _initials(user?.displayName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greeting,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.displayName ?? 'Pengguna',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
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
                  // ── Welcome Card (teal) ───────────────────────
                  const _TodayBanner(),
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
                        loading: () => const _ShimmerBox(height: 80),
                        error: (_, __) =>
                            _errBox('Gagal memuat status kendaraan'),
                        data: (list) {
                          if (list.isEmpty) {
                            return _emptyBox();
                          }
                          return SizedBox(
                            height: 108,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, i) =>
                                  _KendaraanStatusCard(kendaraan: list[i]),
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
                          const Icon(Icons.chevron_right_rounded,
                              size: 18, color: AppColors.primary),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  listAsync.when(
                    loading: () => Column(
                      children: List.generate(
                          3,
                          (_) => const Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: _ShimmerBox(height: 64),
                              )),
                    ),
                    error: (_, __) => _errBox('Gagal memuat perjalanan'),
                    data: (list) => list.isEmpty
                        ? _emptyBox()
                        : Column(
                            children: list
                                .map((p) => _ActivityItem(trip: p))
                                .toList()),
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
            color: Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Colors.red, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: AppTextColors.style(context,
                    fontSize: 13, color: context.adaptiveText),
              ),
            ),
          ]),
        ),
      );

  static Widget _emptyBox() => Builder(
        builder: (context) => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.adaptiveTextSecondary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.adaptiveTextSecondary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_rounded,
                  size: 28, color: context.adaptiveTextMuted),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada perjalanan',
              style: AppTextColors.style(context,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: context.adaptiveText),
            ),
            const SizedBox(height: 2),
            Text(
              'Aktivitas perjalanan akan muncul di sini',
              style: AppTextColors.style(context,
                  fontSize: 12, color: context.adaptiveTextMuted),
            ),
          ]),
        ),
      );
}

class _TodayBanner extends StatelessWidget {
  const _TodayBanner();

  static const _hariIndo = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    "Jum'at",
    'Sabtu',
    'Minggu',
  ];
  static const _bulanIndo = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tanggal =
        '${_hariIndo[now.weekday - 1]}, ${now.day} ${_bulanIndo[now.month - 1]} ${now.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
            top: -14,
            child: Icon(
              Icons.alt_route_rounded,
              size: 84,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_today_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tanggal,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Semoga perjalanan hari ini lancar dan aman.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
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

    final bgColor = VehicleAvatar.bgColor(aktif, isDark: isDark);
    final textColor = VehicleAvatar.iconColor(aktif);
    final dotColor = VehicleAvatar.iconColor(aktif);

    final merekModel = [kendaraan['merek'], kendaraan['model']]
        .where((e) => e != null && '$e'.isNotEmpty)
        .join(' ');

    return Container(
      width: 148,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                aktif ? 'Tersedia' : 'Tidak Tersedia',
                overflow: TextOverflow.ellipsis,
                style: AppTextColors.style(
                  context,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            kendaraan['nomor_polisi'] as String? ?? '-',
            overflow: TextOverflow.ellipsis,
            style: AppTextColors.style(
              context,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          if (merekModel.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              merekModel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextColors.style(
                context,
                fontSize: 11,
                color: textColor,
              ),
            ),
          ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: AppColors.completed, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                VehicleAvatar(aktif: trip.selesai, size: 36, iconSize: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: AppTextColors.style(context,
                          fontSize: 13.5, fontWeight: FontWeight.w700),
                      children: [
                        TextSpan(text: trip.nomorPolisi),
                        if (trip.merekModel.isNotEmpty)
                          TextSpan(
                            text: ' ${trip.merekModel}',
                            style: AppTextColors.style(
                              context,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: context.adaptiveTextSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.completed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 13, color: AppColors.completed),
                      const SizedBox(width: 4),
                      Text(
                        'Selesai',
                        style: AppTextColors.style(context,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.completed),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.alt_route_rounded,
                    size: 15, color: context.adaptiveTextSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${trip.titikJemput}  →  ${trip.titikTujuan}',
                    style: AppTextColors.style(context,
                        fontSize: 13, color: context.adaptiveTextSecondary),
                  ),
                ),
              ],
            ),
            if (trip.jarak != null ||
                trip.waktuTiba != null ||
                trip.penumpang.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (trip.jarak != null)
                    _InfoChip(
                      icon: Icons.speed_rounded,
                      label: '${trip.jarak!.toStringAsFixed(0)} KM',
                    ),
                  if (trip.waktuTiba != null)
                    _InfoChip(
                      icon: Icons.schedule_rounded,
                      label: _formatJam(trip.waktuTiba!),
                    ),
                  if (trip.penumpang.isNotEmpty)
                    _InfoChip(
                      icon: Icons.people_alt_rounded,
                      label: trip.penumpang.length > 1
                          ? '${trip.penumpang.first} +${trip.penumpang.length - 1}'
                          : trip.penumpang.first,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: context.adaptiveTextSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: context.adaptiveTextSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTextColors.style(context,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: context.adaptiveTextSecondary),
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

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.3, end: 0.9).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _a,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
              color: context.adaptiveTextSecondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12)),
        ),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Memotong format waktu "HH:MM:SS" (atau ISO time) menjadi "HH:MM".
String _formatJam(String raw) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw.trim());
  if (match != null) {
    final h = match.group(1)!.padLeft(2, '0');
    final m = match.group(2)!;
    return '$h:$m';
  }
  return raw;
}

String _greetingForHour(int hour) {
  if (hour >= 4 && hour < 11) return 'Selamat pagi';
  if (hour >= 11 && hour < 15) return 'Selamat siang';
  if (hour >= 15 && hour < 18) return 'Selamat sore';
  return 'Selamat malam';
}

String _initials(String? name) {
  final trimmed = name?.trim();
  if (trimmed == null || trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}