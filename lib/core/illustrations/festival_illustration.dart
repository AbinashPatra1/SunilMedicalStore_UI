import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Which decorative motif [FestivalIllustration] draws. Deliberately
/// symbolic/secular (a lamp, confetti, colored powder, a flag, a sweet) —
/// none depict a religious figure, appropriate for a commercial banner.
enum FestivalMotif { diya, confetti, colorSplash, flag, sweet }

/// A simple, hand-drawn flat-style seasonal/festival illustration for the
/// home-banner catalog (Admin > More > Home Banners). One parameterized
/// painter covers every festival banner rather than one bespoke painter
/// each — [motif] picks the shape, [accentColor] tints it per occasion.
class FestivalIllustration extends StatelessWidget {
  const FestivalIllustration({super.key, this.size = 88, required this.motif, required this.accentColor});

  final double size;
  final FestivalMotif motif;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FestivalPainter(motif: motif, accentColor: accentColor)),
    );
  }
}

class _FestivalPainter extends CustomPainter {
  _FestivalPainter({required this.motif, required this.accentColor});

  final FestivalMotif motif;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.48, Paint()..color = accentColor.withValues(alpha: 0.12));
    switch (motif) {
      case FestivalMotif.diya:
        _paintDiya(canvas, w, h);
      case FestivalMotif.confetti:
        _paintConfetti(canvas, w, h);
      case FestivalMotif.colorSplash:
        _paintColorSplash(canvas, w, h);
      case FestivalMotif.flag:
        _paintFlag(canvas, w, h);
      case FestivalMotif.sweet:
        _paintSweet(canvas, w, h);
    }
  }

  void _paintDiya(Canvas canvas, double w, double h) {
    // Lamp saucer: a shallow filled "eye" shape (two arcs meeting at
    // pointed ends), not a thick stroked arc — a thick stroke read as a
    // smile/mouth instead of a lamp base.
    final basePath = Path()
      ..moveTo(w * 0.14, h * 0.62)
      ..quadraticBezierTo(w * 0.5, h * 0.46, w * 0.86, h * 0.62)
      ..quadraticBezierTo(w * 0.5, h * 0.84, w * 0.14, h * 0.62)
      ..close();
    canvas.drawPath(basePath, Paint()..color = accentColor);
    canvas.drawPath(
      basePath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012,
    );

    final flamePath = Path()
      ..moveTo(w * 0.5, h * 0.22)
      ..quadraticBezierTo(w * 0.61, h * 0.36, w * 0.5, h * 0.5)
      ..quadraticBezierTo(w * 0.39, h * 0.36, w * 0.5, h * 0.22);
    canvas.drawPath(flamePath, Paint()..color = const Color(0xFFFFC94D));
    final innerFlame = Path()
      ..moveTo(w * 0.5, h * 0.3)
      ..quadraticBezierTo(w * 0.555, h * 0.38, w * 0.5, h * 0.46)
      ..quadraticBezierTo(w * 0.445, h * 0.38, w * 0.5, h * 0.3);
    canvas.drawPath(innerFlame, Paint()..color = const Color(0xFFFF7A3D));

    final sparklePaint = Paint()..color = accentColor.withValues(alpha: 0.7);
    for (final p in [Offset(w * 0.16, h * 0.28), Offset(w * 0.84, h * 0.3), Offset(w * 0.2, h * 0.6)]) {
      _drawSparkle(canvas, p, w * 0.045, sparklePaint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r * 0.28, center.dy - r * 0.28)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx + r * 0.28, center.dy + r * 0.28)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r * 0.28, center.dy + r * 0.28)
      ..lineTo(center.dx - r, center.dy)
      ..lineTo(center.dx - r * 0.28, center.dy - r * 0.28)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _paintConfetti(Canvas canvas, double w, double h) {
    final burstCenter = Offset(w * 0.5, h * 0.42);
    final rayPaint = Paint()
      ..color = accentColor
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi;
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(burstCenter + dir * w * 0.12, burstCenter + dir * w * 0.32, rayPaint);
      canvas.drawCircle(burstCenter + dir * w * 0.32, w * 0.02, Paint()..color = accentColor);
    }
    canvas.drawCircle(burstCenter, w * 0.06, Paint()..color = const Color(0xFFFFC94D));

    final colors = [accentColor, const Color(0xFFFFC94D), const Color(0xFF57C08C)];
    final pieces = [Offset(w * 0.2, h * 0.78), Offset(w * 0.75, h * 0.8), Offset(w * 0.55, h * 0.88), Offset(w * 0.3, h * 0.62)];
    for (var i = 0; i < pieces.length; i++) {
      canvas.save();
      canvas.translate(pieces[i].dx, pieces[i].dy);
      canvas.rotate(i * 0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w * 0.09, height: w * 0.045),
          Radius.circular(w * 0.015),
        ),
        Paint()..color = colors[i % colors.length],
      );
      canvas.restore();
    }
  }

  void _paintColorSplash(Canvas canvas, double w, double h) {
    final palette = [accentColor, const Color(0xFF57A8E0), const Color(0xFFFFC94D), const Color(0xFFE0567A)];
    final centers = [Offset(w * 0.36, h * 0.38), Offset(w * 0.64, h * 0.36), Offset(w * 0.46, h * 0.62), Offset(w * 0.68, h * 0.6)];
    for (var i = 0; i < centers.length; i++) {
      canvas.drawCircle(centers[i], w * 0.2, Paint()..color = palette[i % palette.length].withValues(alpha: 0.85));
    }
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (final p in [Offset(w * 0.3, h * 0.3), Offset(w * 0.7, h * 0.28), Offset(w * 0.4, h * 0.72), Offset(w * 0.75, h * 0.72)]) {
      canvas.drawCircle(p, w * 0.022, dotPaint);
    }
  }

  void _paintFlag(Canvas canvas, double w, double h) {
    canvas.drawLine(
      Offset(w * 0.28, h * 0.18),
      Offset(w * 0.28, h * 0.86),
      Paint()
        ..color = const Color(0xFF6B4A2B)
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round,
    );
    final bandH = h * 0.18;
    Rect bandRect(double top) => Rect.fromLTWH(w * 0.28, top, w * 0.5, bandH);
    canvas.drawRect(bandRect(h * 0.2), Paint()..color = const Color(0xFFFF9933));
    canvas.drawRect(bandRect(h * 0.2 + bandH), Paint()..color = Colors.white);
    canvas.drawRect(bandRect(h * 0.2 + bandH * 2), Paint()..color = const Color(0xFF138808));

    final chakraCenter = Offset(w * 0.53, h * 0.2 + bandH * 1.5);
    final chakraPaint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012;
    canvas.drawCircle(chakraCenter, bandH * 0.32, chakraPaint);
    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi;
      canvas.drawLine(
        chakraCenter,
        chakraCenter + Offset(math.cos(angle), math.sin(angle)) * bandH * 0.32,
        chakraPaint,
      );
    }
  }

  void _paintSweet(Canvas canvas, double w, double h) {
    final bodyPath = Path()
      ..moveTo(w * 0.5, h * 0.22)
      ..quadraticBezierTo(w * 0.78, h * 0.42, w * 0.68, h * 0.75)
      ..quadraticBezierTo(w * 0.6, h * 0.88, w * 0.5, h * 0.88)
      ..quadraticBezierTo(w * 0.4, h * 0.88, w * 0.32, h * 0.75)
      ..quadraticBezierTo(w * 0.22, h * 0.42, w * 0.5, h * 0.22)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = accentColor.withValues(alpha: 0.9));

    final pleatPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round;
    for (final dx in [-0.1, 0.0, 0.1]) {
      canvas.drawLine(Offset(w * (0.5 + dx), h * 0.24), Offset(w * (0.5 + dx * 1.6), h * 0.42), pleatPaint);
    }

    final leafPath = Path()
      ..moveTo(w * 0.5, h * 0.22)
      ..quadraticBezierTo(w * 0.58, h * 0.1, w * 0.68, h * 0.12)
      ..quadraticBezierTo(w * 0.6, h * 0.2, w * 0.5, h * 0.22);
    canvas.drawPath(leafPath, Paint()..color = const Color(0xFF57A15B));

    final dotPaint = Paint()..color = accentColor.withValues(alpha: 0.5);
    for (final p in [Offset(w * 0.22, h * 0.85), Offset(w * 0.78, h * 0.85), Offset(w * 0.5, h * 0.94)]) {
      canvas.drawCircle(p, w * 0.025, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FestivalPainter oldDelegate) =>
      oldDelegate.motif != motif || oldDelegate.accentColor != accentColor;
}
