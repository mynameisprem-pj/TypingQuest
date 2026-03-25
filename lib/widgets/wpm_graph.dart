import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Draws a live WPM graph from a list of WPM samples.
/// Call [addSample] every second to update.
class WpmGraph extends StatelessWidget {
  final List<int> samples;  // WPM values over time
  final int maxVisible;     // max samples displayed at once
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
        child: Center(
          child: Text(
            'Start typing to see graph...',
            style: AppTheme.body(12, color: AppTheme.textMuted),
          ),
        ),
      );
    }

    final visible = samples.length > maxVisible
        ? samples.sublist(samples.length - maxVisible)
        : samples;

    return RepaintBoundary(
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: _WpmGraphPainter(samples: visible),
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: Text(
                '${samples.last} WPM',
                style: AppTheme.body(11,
                    color: AppTheme.primary.withValues(alpha: 0.8)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────
class _WpmGraphPainter extends CustomPainter {
  final List<int> samples;

  _WpmGraphPainter({required this.samples});

  // ── Cached paint objects ──────────────────────────────────────────────
  // Creating Paint on every frame is wasteful. These are created once and
  // reused across all paint calls (the shader is re-assigned per size).

  static final Paint _gridPaint = Paint()
    ..color       = const Color(0x0F5C7CFA) // primary @ 6 %
    ..strokeWidth = 1;

  static final Paint _linePaint = Paint()
    ..color       = AppTheme.primary
    ..strokeWidth = 2
    ..strokeCap   = StrokeCap.round
    ..strokeJoin  = StrokeJoin.round
    ..style       = PaintingStyle.stroke;

  // Dot at the current sample point — solid, no blur.
  // MaskFilter.blur is one of Flutter's most expensive canvas ops and makes
  // no visible difference on small dots. Replaced with a plain circle.
  static final Paint _dotInnerPaint = Paint()..color = AppTheme.primary;
  static final Paint _dotOuterPaint = Paint()
    ..color = const Color(0x4D5C7CFA); // primary @ 30 %

  // Fill paint reuses a single instance; only the shader is updated per call.
  final Paint _fillPaint = Paint();

  // ── Paint ─────────────────────────────────────────────────────────────
  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;

    final maxWpm    = samples.reduce((a, b) => a > b ? a : b).toDouble();
    final displayMax = maxWpm < 20 ? 30.0 : maxWpm * 1.2;

    // Grid lines
    for (int i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _gridPaint);
    }

    // Pre-compute points once — used for both fill path and line path.
    final points = List<Offset>.generate(samples.length, (i) {
      final x = i / (samples.length - 1) * size.width;
      final y = size.height - (samples[i] / displayMax) * size.height;
      return Offset(x, y);
    });

    // Gradient fill
    final fillPath = Path()..moveTo(0, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    _fillPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end:   Alignment.bottomCenter,
      colors: [
        AppTheme.primary.withValues(alpha: 0.25),
        AppTheme.primary.withValues(alpha: 0.02),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, _fillPaint);

    // Smooth line using cubic Bézier curves
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpX  = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(linePath, _linePaint);

    // Current-value dot — outer ring + inner solid (no blur/glow).
    final last = points.last;
    canvas.drawCircle(last, 5.5, _dotOuterPaint);
    canvas.drawCircle(last, 3.0, _dotInnerPaint);
  }

  // ── Repaint guard ──────────────────────────────────────────────────────
  // Only repaint when the data actually changed — compare length and the
  // most-recent value. This prevents unnecessary redraws when the parent
  // rebuilds for unrelated state (cursor blink, timer tick, etc.).
  @override
  bool shouldRepaint(_WpmGraphPainter old) {
    if (old.samples.length != samples.length) return true;
    if (samples.isEmpty) return false;
    return old.samples.last != samples.last;
  }
}