import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A simple, hand-drawn flat-style illustration of a cute open, empty box —
/// part of the "calm clinical minimal" redesign (backlog #14), used for
/// "nothing here yet" moments that aren't catalog/search related: an empty
/// cart, no orders/prescriptions/addresses/payment methods yet. Visually
/// paired with [SearchEmptyIllustration] (same blob + quirky-face language)
/// so the two read as one small, consistent illustration set rather than
/// a bespoke drawing per screen.
class EmptyBoxIllustration extends StatelessWidget {
  const EmptyBoxIllustration({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EmptyBoxPainter(
          boxColor: scheme.primary,
          flapColor: scheme.secondary,
          faceColor: scheme.onPrimary,
          blobColor: scheme.primary.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

class _EmptyBoxPainter extends CustomPainter {
  _EmptyBoxPainter({
    required this.boxColor,
    required this.flapColor,
    required this.faceColor,
    required this.blobColor,
  });

  final Color boxColor;
  final Color flapColor;
  final Color faceColor;
  final Color blobColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft background blob, same language as SearchEmptyIllustration.
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.48, Paint()..color = blobColor);

    // Open flaps, behind the box body — two soft triangles tipped outward.
    final flapPaint = Paint()..color = flapColor;
    final leftFlap = Path()
      ..moveTo(w * 0.28, h * 0.46)
      ..lineTo(w * 0.1, h * 0.26)
      ..lineTo(w * 0.42, h * 0.4)
      ..close();
    final rightFlap = Path()
      ..moveTo(w * 0.72, h * 0.46)
      ..lineTo(w * 0.9, h * 0.26)
      ..lineTo(w * 0.58, h * 0.4)
      ..close();
    canvas.drawPath(leftFlap, flapPaint);
    canvas.drawPath(rightFlap, flapPaint);

    // Box body — a slightly tapered trapezoid.
    final bodyRect = Rect.fromLTRB(w * 0.2, h * 0.42, w * 0.8, h * 0.78);
    final bodyRRect = RRect.fromRectAndCorners(
      bodyRect,
      bottomLeft: Radius.circular(w * 0.05),
      bottomRight: Radius.circular(w * 0.05),
    );
    canvas.drawRRect(bodyRRect, Paint()..color = boxColor);

    // Center seam line down the front.
    final seamPaint = Paint()
      ..color = faceColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.5, h * 0.42), Offset(w * 0.5, h * 0.5), seamPaint);

    // A small curious face on the box front: closed happy eyes + an "o" mouth.
    final linePaint = Paint()
      ..color = faceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;
    final faceCenter = Offset(w * 0.5, h * 0.6);
    for (final dx in [-w * 0.13, w * 0.13]) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(faceCenter.dx + dx, faceCenter.dy), width: w * 0.12, height: w * 0.12),
        math.pi,
        -math.pi * 0.8,
        false,
        linePaint,
      );
    }
    canvas.drawCircle(Offset(faceCenter.dx, faceCenter.dy + w * 0.11), w * 0.04, Paint()..color = faceColor);
  }

  @override
  bool shouldRepaint(covariant _EmptyBoxPainter oldDelegate) => false;
}
