import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A simple, hand-drawn flat-style success illustration — a checkmark badge
/// with a few scattered confetti pieces — used for the order-placed
/// confirmation dialog (backlog #14).
class OrderSuccessIllustration extends StatelessWidget {
  const OrderSuccessIllustration({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _OrderSuccessPainter(
          badgeColor: scheme.primary,
          checkColor: scheme.onPrimary,
          confettiColors: [scheme.tertiary, scheme.secondary, scheme.primary.withValues(alpha: 0.6)],
          blobColor: scheme.primary.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

class _OrderSuccessPainter extends CustomPainter {
  _OrderSuccessPainter({
    required this.badgeColor,
    required this.checkColor,
    required this.confettiColors,
    required this.blobColor,
  });

  final Color badgeColor;
  final Color checkColor;
  final List<Color> confettiColors;
  final Color blobColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.52);

    canvas.drawCircle(center, w * 0.48, Paint()..color = blobColor);

    final confetti = [
      (Offset(w * 0.14, h * 0.22), math.pi * 0.15, confettiColors[0]),
      (Offset(w * 0.86, h * 0.2), -math.pi * 0.2, confettiColors[1]),
      (Offset(w * 0.85, h * 0.72), math.pi * 0.3, confettiColors[2]),
      (Offset(w * 0.12, h * 0.75), -math.pi * 0.1, confettiColors[0]),
      (Offset(w * 0.5, h * 0.06), math.pi * 0.5, confettiColors[1]),
    ];
    for (final piece in confetti) {
      canvas.save();
      canvas.translate(piece.$1.dx, piece.$1.dy);
      canvas.rotate(piece.$2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w * 0.09, height: w * 0.045),
          Radius.circular(w * 0.02),
        ),
        Paint()..color = piece.$3,
      );
      canvas.restore();
    }

    final badgeRadius = w * 0.32;
    canvas.drawCircle(center, badgeRadius, Paint()..color = badgeColor);

    final checkPaint = Paint()
      ..color = checkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(center.dx - badgeRadius * 0.45, center.dy + badgeRadius * 0.02)
      ..lineTo(center.dx - badgeRadius * 0.1, center.dy + badgeRadius * 0.38)
      ..lineTo(center.dx + badgeRadius * 0.5, center.dy - badgeRadius * 0.35);
    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _OrderSuccessPainter oldDelegate) => false;
}
