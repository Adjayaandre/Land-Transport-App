import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_text_colors.dart';

/// Widget foto picker — tampilkan preview foto + opsi ambil/ganti via kamera atau galeri.
class FotoPicker extends StatelessWidget {
  final Uint8List? fotoBytes;
  final String label;
  final IconData icon;
  final void Function(Uint8List bytes) onFotoSelected;
  final VoidCallback? onHapus;

  const FotoPicker({
    super.key,
    required this.fotoBytes,
    required this.label,
    required this.icon,
    required this.onFotoSelected,
    this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPilihSumber(context),
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: fotoBytes != null
              ? Colors.transparent
              : Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: fotoBytes != null
                ? AppColors.completed.withValues(alpha: 0.5)
                : Theme.of(context).dividerTheme.color ?? AppColors.border,
            width: fotoBytes != null ? 1.5 : 1,
          ),
        ),
        child: fotoBytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.memory(fotoBytes!, fit: BoxFit.cover),
                  ),
                  // Tombol aksi kanan atas: fullscreen, ganti, hapus
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionBtn(
                          context,
                          Icons.fullscreen_rounded,
                          () => _showFullscreenPreview(context),
                        ),
                        const SizedBox(width: 6),
                        _actionBtn(
                          context,
                          Icons.camera_alt_rounded,
                          () => _showPilihSumber(context),
                        ),
                        if (onHapus != null) ...[
                          const SizedBox(width: 6),
                          _actionBtn(
                            context,
                            Icons.delete_outline_rounded,
                            onHapus!,
                            color: AppColors.cancelled,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Badge "Foto tersimpan"
                  Positioned(
                    bottom: 6,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.completed.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle,
                              size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Foto tersimpan',
                            style: AppTextColors.style(context,
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 30, color: context.adaptiveTextMuted),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: AppTextColors.style(
                      context,
                      fontSize: 13,
                      color: context.adaptiveTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ketuk untuk ambil foto',
                    style: AppTextColors.style(
                      context,
                      fontSize: 11,
                      color: context.adaptiveTextMuted,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _actionBtn(BuildContext context, IconData icon, VoidCallback onTap,
      {Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  /// Buka preview fullscreen dengan zoom & pan.
  void _showFullscreenPreview(BuildContext context) {
    if (fotoBytes == null) return;

    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FotoFullscreenView(
            fotoBytes: fotoBytes!,
            label: label,
            onGantiFoto: () {
              Navigator.of(context, rootNavigator: true).pop();
              _showPilihSumber(context);
            },
            onHapus: onHapus != null
                ? () {
                    Navigator.of(context, rootNavigator: true).pop();
                    onHapus!();
                  }
                : null,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _showPilihSumber(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Pilih Sumber Foto',
                style: AppTextColors.style(ctx,
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.primary),
              ),
              title: const Text('Ambil Foto',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Gunakan kamera perangkat'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: Color(0xFF7C3AED)),
              ),
              title: const Text('Pilih dari Galeri',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Pilih foto dari penyimpanan'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    onFotoSelected(bytes);
  }
}

// ---------------------------------------------------------------------------
// Fullscreen preview page
// ---------------------------------------------------------------------------

class _FotoFullscreenView extends StatefulWidget {
  final Uint8List fotoBytes;
  final String label;
  final VoidCallback onGantiFoto;
  final VoidCallback? onHapus;

  const _FotoFullscreenView({
    required this.fotoBytes,
    required this.label,
    required this.onGantiFoto,
    this.onHapus,
  });

  @override
  State<_FotoFullscreenView> createState() => _FotoFullscreenViewState();
}

class _FotoFullscreenViewState extends State<_FotoFullscreenView>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformCtrl = TransformationController();
  late final AnimationController _resetAnimCtrl;
  Animation<Matrix4>? _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _resetAnimCtrl.addListener(() {
      if (_resetAnimation != null) {
        _transformCtrl.value = _resetAnimation!.value;
      }
    });
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    _resetAnimCtrl.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _resetAnimation = Matrix4Tween(
      begin: _transformCtrl.value,
      end: Matrix4.identity(),
    ).animate(
      CurvedAnimation(parent: _resetAnimCtrl, curve: Curves.easeOutCubic),
    );
    _resetAnimCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dismissible background
          GestureDetector(
            onTap: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Container(color: Colors.transparent),
          ),

          // Zoomable image
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: InteractiveViewer(
                transformationController: _transformCtrl,
                minScale: 0.5,
                maxScale: 5.0,
                clipBehavior: Clip.none,
                onInteractionEnd: (details) {
                  // Auto-reset jika zoom di bawah 1x
                  if (_transformCtrl.value.getMaxScaleOnAxis() < 1.0) {
                    _resetZoom();
                  }
                },
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      widget.fotoBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      // Tombol tutup
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 26),
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true).pop(),
                        tooltip: 'Tutup',
                      ),
                      const SizedBox(width: 4),
                      // Label
                      Expanded(
                        child: Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Reset zoom
                      IconButton(
                        icon: const Icon(Icons.zoom_out_map_rounded,
                            color: Colors.white, size: 22),
                        onPressed: _resetZoom,
                        tooltip: 'Reset Zoom',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom action bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ganti foto
                      _BottomAction(
                        icon: Icons.camera_alt_rounded,
                        label: 'Ganti Foto',
                        onTap: widget.onGantiFoto,
                      ),
                      if (widget.onHapus != null) ...[
                        const SizedBox(width: 32),
                        // Hapus foto
                        _BottomAction(
                          icon: Icons.delete_outline_rounded,
                          label: 'Hapus',
                          color: const Color(0xFFEF4444),
                          onTap: widget.onHapus!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Hint teks pinch-to-zoom (muncul di tengah bawah)
          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pinch_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Cubit untuk zoom',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol aksi di bottom bar fullscreen.
class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}