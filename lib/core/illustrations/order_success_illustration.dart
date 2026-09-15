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
          haloColor: scheme.primary.withValues(alpha: 0.16),
        ),
      ),
    );
  }
}

class _OrderSuccessPainter extends CustomPainter {
  _OrderSuccessPainter({
    required this.badgeColor,
    required this.checkColor,
    required this.haloColor,
  });

  final Color badgeColor;
  final Color checkColor;
  final Color haloColor;

  // Fixed celebratory colors (not theme-derived) so the confetti reads as
  // confetti — distinct, saturated hues — against either a light or dark
  // background, rather than blending into a teal-dominant color scheme.
  static const _confettiColors = [Color(0xFFFFC94D), Color(0xFFFF6F91), Color(0xFF57C08C)];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.52);
    final badgeRadius = w * 0.32;

    canvas.drawCircle(center, w * 0.48, Paint()..color = haloColor);

    // Confetti sits close around the badge, evenly spaced, so it reads as
    // one cohesive "burst" from the checkmark rather than debris scattered
    // independently across the box.
    final confettiOrbit = badgeRadius * 1.55;
    const angles = [-100.0, -35.0, 15.0, 70.0, 130.0, 195.0];
    for (var i = 0; i < angles.length; i++) {
      final rad = angles[i] * math.pi / 180;
      final pos = center + Offset(math.cos(rad), math.sin(rad)) * confettiOrbit;
      final color = _confettiColors[i % _confettiColors.length];
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      if (i.isEven) {
        canvas.rotate(rad + math.pi / 4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w * 0.09, height: w * 0.045),
            Radius.circular(w * 0.02),
          ),
          Paint()..color = color,
        );
      } else {
        canvas.drawCircle(Offset.zero, w * 0.028, Paint()..color = color);
      }
      canvas.restore();
    }

    canvas.drawCircle(center, badgeRadius, Paint()..color = badgeColor);

    final checkPaint = Paint()
      ..color = checkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(center.dx - badgeRadius * 0.42, center.dy + badgeRadius * 0.02)
      ..lineTo(center.dx - badgeRadius * 0.08, center.dy + badgeRadius * 0.36)
      ..lineTo(center.dx + badgeRadius * 0.48, center.dy - badgeRadius * 0.32);
    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _OrderSuccessPainter oldDelegate) => false;
}
