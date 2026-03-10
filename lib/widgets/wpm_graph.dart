import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Draws a live WPM graph from a list of WPM samples.
/// Call [addSample] every second to update.
class WpmGraph extends StatelessWidget {
  final List<int> samples;       // list of WPM values over time
  final int maxVisible;          // how many samples to show
  final double height;

  const WpmGraph({
    super.key,
    required this.samples,
    this.maxVisible = 60,
    this.height = 72,
  });

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(child: Text('Start typing to see graph...', style: AppTheme.body(12, color: AppTheme.textMuted))),
      );
    }

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _WpmGraphPainter(
          samples: samples.length > maxVisible ? samples.sublist(samples.length - maxVisible) : samples,
        ),
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8, top: 4),
            child: Text(
              '${samples.last} WPM',
              style: AppTheme.body(11, color: AppTheme.primary.withValues(alpha: 0.8)),
            ),
          ),
        ),
      ),
    );
  }
}

class _WpmGraphPainter extends CustomPainter {
  final List<int> samples;

  _WpmGraphPainter({required this.samples});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;

    final maxWpm = samples.reduce((a, b) => a > b ? a : b).toDouble();
    final displayMax = maxWpm < 20 ? 30.0 : maxWpm * 1.2;

    // Grid lines
    final gridPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Gradient fill
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < samples.length; i++) {
      final x = i / (samples.length - 1) * size.width;
      final y = size.height - (samples[i] / displayMax) * size.height;
      points.add(Offset(x, y));
    }

    path.moveTo(0, size.height);
    for (final p in points) {
      path.lineTo(p.dx, p.dy);
    }
    path.lineTo(size.width, size.height);
    path.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppTheme.primary.withValues(alpha: 0.25), AppTheme.primary.withValues(alpha: 0.02)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      // Smooth curve using cubic bezier
      final prev = points[i - 1];
      final curr = points[i];
      final cpX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Current point glow
    if (points.isNotEmpty) {
      final last = points.last;
      final glowPaint = Paint()
        ..color = AppTheme.primary.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(last, 5, glowPaint);
      canvas.drawCircle(last, 3, Paint()..color = AppTheme.primary);
    }
  }

  @override
  bool shouldRepaint(_WpmGraphPainter old) => old.samples != samples;
}