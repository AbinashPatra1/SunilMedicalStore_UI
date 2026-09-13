import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A simple, hand-drawn flat-style illustration of a cute waving character
/// next to a discount badge — part of the "calm clinical minimal" redesign
/// (backlog #14), used on the dashboard promo banner.
///
/// Drawn with [CustomPainter] primitives rather than an external
/// asset/SVG illustration pack: no logo or illustration set exists for this
/// app yet, so a hand-coded shape avoids an extra dependency and licensing
/// question, and recolors itself automatically from the active
/// [ColorScheme] in both light and dark themes.
class HappyDiscountIllustration extends StatelessWidget {
  const HappyDiscountIllustration({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HappyDiscountPainter(
          skinTone: const Color(0xFFF2B98A),
          hairColor: const Color(0xFF3E2723),
          shirtColor: scheme.primary,
          badgeColor: scheme.tertiary,
          blobColor: scheme.primary.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

class _HappyDiscountPainter extends CustomPainter {
  _HappyDiscountPainter({
    required this.skinTone,
    required this.hairColor,
    required this.shirtColor,
    required this.badgeColor,
    required this.blobColor,
  });

  final Color skinTone;
  final Color hairColor;
  final Color shirtColor;
  final Color badgeColor;
  final Color blobColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft background blob.
    canvas.drawCircle(Offset(w * 0.48, h * 0.52), w * 0.48, Paint()..color = blobColor);

    // Body (rounded shirt).
    final bodyRect = Rect.fromCenter(center: Offset(w * 0.46, h * 0.8), width: w * 0.48, height: h * 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.16)),
      Paint()..color = shirtColor,
    );

    // Waving arm, raised up and out to the right.
    final armPaint = Paint()
      ..color = skinTone
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.085
      ..strokeCap = StrokeCap.round;
    final armPath = Path()
      ..moveTo(w * 0.62, h * 0.66)
      ..quadraticBezierTo(w * 0.9, h * 0.52, w * 0.76, h * 0.26);
    canvas.drawPath(armPath, armPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.25), w * 0.06, Paint()..color = skinTone);

    // Head.
    final headCenter = Offset(w * 0.44, h * 0.42);
    final headRadius = w * 0.22;
    canvas.drawCircle(headCenter, headRadius, Paint()..color = skinTone);

    // Hair (top cap).
    final hairRect = Rect.fromCircle(center: headCenter, radius: headRadius * 1.05);
    canvas.drawArc(hairRect, math.pi, math.pi, true, Paint()..color = hairColor);

    // Blush cheeks.
    final blushPaint = Paint()..color = const Color(0xFFFFA8A0).withValues(alpha: 0.55);
    canvas.drawCircle(
      Offset(headCenter.dx - headRadius * 0.56, headCenter.dy + headRadius * 0.18),
      headRadius * 0.15,
      blushPaint,
    );
    canvas.drawCircle(
      Offset(headCenter.dx + headRadius * 0.56, headCenter.dy + headRadius * 0.18),
      headRadius * 0.15,
      blushPaint,
    );

    // Happy closed eyes — small upward-curving arcs (^ ^).
    final linePaint = Paint()
      ..color = hairColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;
    final eyeY = headCenter.dy - headRadius * 0.02;
    for (final dx in [-headRadius * 0.4, headRadius * 0.4]) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(headCenter.dx + dx, eyeY), width: headRadius * 0.36, height: headRadius * 0.36),
        math.pi,
        -math.pi * 0.8,
        false,
        linePaint,
      );
    }

    // Smile.
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(headCenter.dx, headCenter.dy + headRadius * 0.18),
        width: headRadius * 0.7,
        height: headRadius * 0.55,
      ),
      math.pi * 0.12,
      math.pi * 0.76,
      false,
      linePaint..strokeWidth = w * 0.024,
    );

    // Floating discount badge near the raised hand.
    final badgeCenter = Offset(w * 0.84, h * 0.13);
    canvas.drawCircle(badgeCenter, w * 0.135, Paint()..color = badgeColor);
    final tp = TextPainter(
      text: TextSpan(
        text: '%',
        style: TextStyle(color: Colors.white, fontSize: w * 0.15, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, badgeCenter - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _HappyDiscountPainter oldDelegate) => false;
}
