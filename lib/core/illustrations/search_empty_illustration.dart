import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A simple, hand-drawn flat-style illustration of a cute magnifying glass
/// — part of the "calm clinical minimal" redesign (backlog #14), used for
/// "nothing here yet" moments in the catalog: no search query typed yet, no
/// results for a query, or an empty product category.
class SearchEmptyIllustration extends StatelessWidget {
  const SearchEmptyIllustration({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SearchEmptyPainter(
          lensColor: scheme.surfaceContainerHighest,
          handleColor: scheme.primary,
          faceColor: scheme.onSurfaceVariant,
          blobColor: scheme.primary.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

class _SearchEmptyPainter extends CustomPainter {
  _SearchEmptyPainter({
    required this.lensColor,
    required this.handleColor,
    required this.faceColor,
    required this.blobColor,
  });

  final Color lensColor;
  final Color handleColor;
  final Color faceColor;
  final Color blobColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.44, h * 0.44);
    final lensRadius = w * 0.32;

    // Soft background blob.
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.48, Paint()..color = blobColor);

    // Handle, behind the lens.
    final handlePaint = Paint()
      ..color = handleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center + Offset(lensRadius * 0.75, lensRadius * 0.75),
      Offset(w * 0.86, h * 0.86),
      handlePaint,
    );

    // Lens rim + fill.
    canvas.drawCircle(center, lensRadius, Paint()..color = lensColor);
    canvas.drawCircle(
      center,
      lensRadius,
      Paint()
        ..color = handleColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045,
    );

    // A small curious face on the lens: closed happy eyes + an "o" mouth.
    final linePaint = Paint()
      ..color = faceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round;
    final eyeY = center.dy - lensRadius * 0.12;
    for (final dx in [-lensRadius * 0.38, lensRadius * 0.38]) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx + dx, eyeY), width: lensRadius * 0.34, height: lensRadius * 0.34),
        math.pi,
        -math.pi * 0.8,
        false,
        linePaint,
      );
    }
    canvas.drawCircle(Offset(center.dx, center.dy + lensRadius * 0.32), lensRadius * 0.12, Paint()..color = faceColor);
  }

  @override
  bool shouldRepaint(covariant _SearchEmptyPainter oldDelegate) => false;
}
