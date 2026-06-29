import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Canvas tanda tangan — pakai [Listener] agar tidak bentrok dengan scroll.
class SignaturePad extends StatefulWidget {
  final List<List<Offset?>> strokes;
  final VoidCallback? onDrawStart;
  final VoidCallback? onDrawEnd;
  final double height;

  const SignaturePad({
    super.key,
    required this.strokes,
    this.onDrawStart,
    this.onDrawEnd,
    this.height = 150,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  void _repaint() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            widget.onDrawStart?.call();
            widget.strokes.add([event.localPosition]);
            _repaint();
          },
          onPointerMove: (event) {
            if (widget.strokes.isEmpty) {
              widget.strokes.add([event.localPosition]);
            } else {
              widget.strokes.last.add(event.localPosition);
            }
            _repaint();
          },
          onPointerUp: (_) {
            if (widget.strokes.isNotEmpty) {
              widget.strokes.last.add(null);
            }
            widget.onDrawEnd?.call();
            _repaint();
          },
          onPointerCancel: (_) {
            widget.onDrawEnd?.call();
            _repaint();
          },
          child: CustomPaint(
            painter: _SignaturePainter(widget.strokes),
            size: Size.infinite,
            child: widget.strokes.isEmpty
                ? const Center(
                    child: Text(
                      'Tanda tangan di sini',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset?>> strokes;

  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      final path = Path();
      var started = false;
      for (final point in stroke) {
        if (point == null) {
          started = false;
        } else if (!started) {
          path.moveTo(point.dx, point.dy);
          started = true;
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => true;
}
