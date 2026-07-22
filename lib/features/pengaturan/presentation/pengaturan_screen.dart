import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_text_colors.dart';
import '../../auth/domain/auth_provider.dart';

class PengaturanScreen extends ConsumerWidget {
  const PengaturanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'LTM',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Pengaturan Aplikasi'),
          ],
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),

          _buildToggleItem(
            context: context,
            icon: Icons.notifications_outlined,
            iconColor: Colors.red,
            iconBg: isDarkMode ? const Color(0xFF3B1C1C) : const Color(0xFFFFEBEE),
            label: 'Notifikasi',
            value: true,
            onChanged: (_) {},
          ),

          _divider(context),

          _buildToggleItem(
            context: context,
            icon: Icons.brightness_6_outlined,
            iconColor: const Color(0xFFF59E0B),
            iconBg: isDarkMode ? const Color(0xFF3D3010) : const Color(0xFFFFF8E1),
            label: 'Mode Gelap',
            trailing: Icon(
              isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
            value: isDarkMode,
            onChanged: (enabled) {
              ref.read(themeModeProvider.notifier).setDarkMode(enabled);
            },
          ),

          const SizedBox(height: 20),

          _buildActionItem(
            context: context,
            icon: Icons.power_settings_new_rounded,
            iconColor: AppColors.cancelled,
            iconBg: isDarkMode ? const Color(0xFF3B1C1C) : const Color(0xFFFFEBEE),
            label: 'Keluar',
            labelColor: context.adaptiveText,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Keluar'),
                  content: const Text('Apakah kamu yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cancelled,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(50, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                ref.read(authProvider.notifier).logout();
              }
            },
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'LTD v1.0.0',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing ?? const SizedBox.shrink(),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required VoidCallback onTap,
    Color? labelColor,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: theme.colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) => Divider(
        height: 1,
        indent: 72,
        endIndent: 0,
        color: Theme.of(context).dividerTheme.color,
      );
}
