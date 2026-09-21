import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_palette.dart';
import 'package:sunil_medical_store/features/medicines/domain/product.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_category.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_type.dart';

/// What a product looks like in the catalog until it has a real photo.
enum ProductMotif {
  strip,
  bottle,
  syringe,
  tube,
  jar,
  device,
  dropper,
  box,
  capsule,
}

/// Picks a motif from the product's type first, then its category. Falls
/// back to a plain capsule when neither says anything specific.
ProductMotif motifFor(ProductType? type, String category) {
  switch (type) {
    case ProductType.tabletDrug:
      return ProductMotif.strip;
    case ProductType.liquidDrug:
      return ProductMotif.bottle;
    case ProductType.injection:
      return ProductMotif.syringe;
    case ProductType.nonOralDrug:
      return ProductMotif.tube;
    case ProductType.others:
    case null:
      break;
  }
  return switch (ProductCategory.fromLabel(category)) {
    ProductCategory.monitoringDevices => ProductMotif.device,
    ProductCategory.vitaminsSupplements ||
    ProductCategory.proteinSupplements ||
    ProductCategory.foodNutrition ||
    ProductCategory.ayurvedicWellness => ProductMotif.jar,
    ProductCategory.skinCare ||
    ProductCategory.hairCare ||
    ProductCategory.menCare ||
    ProductCategory.womenCare ||
    ProductCategory.babyCare ||
    ProductCategory.oralCare => ProductMotif.tube,
    ProductCategory.eyeCare => ProductMotif.dropper,
    ProductCategory.coldCoughFever => ProductMotif.bottle,
    ProductCategory.firstAid ||
    ProductCategory.sexualWellness => ProductMotif.box,
    ProductCategory.prescriptionDrugs => ProductMotif.strip,
    _ => ProductMotif.capsule,
  };
}

AppAccent _accentFor(ProductMotif motif) => switch (motif) {
  ProductMotif.strip => AppAccent.mint,
  ProductMotif.bottle => AppAccent.sky,
  ProductMotif.syringe => AppAccent.pink,
  ProductMotif.tube => AppAccent.peach,
  ProductMotif.jar => AppAccent.amber,
  ProductMotif.device => AppAccent.lavender,
  ProductMotif.dropper => AppAccent.sky,
  ProductMotif.box => AppAccent.mint,
  ProductMotif.capsule => AppAccent.peach,
};

/// The product's photo when it has one, otherwise a flat illustration on a
/// pastel tile. Sized by its parent (or [height]/[width]); the drawing stays
/// square and centred.
class ProductIllustration extends StatelessWidget {
  const ProductIllustration({
    super.key,
    required this.category,
    this.type,
    this.imageUrl,
    this.width,
    this.height,
    this.radius = 16,
  }) : isLabTest = false;

  ProductIllustration.forProduct({
    super.key,
    required Product product,
    this.width,
    this.height,
    this.radius = 16,
  }) : category = product.category,
       type = product.type,
       imageUrl = product.imageUrl,
       isLabTest = false;

  /// A lab-test line: no product motif, just a sky-blue tile with a
  /// microscope glyph.
  const ProductIllustration.labTest({
    super.key,
    this.width,
    this.height,
    this.radius = 16,
  }) : category = '',
       type = null,
       imageUrl = null,
       isLabTest = true;

  final String category;
  final ProductType? type;
  final String? imageUrl;
  final bool isLabTest;
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (isLabTest) {
      return SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppAccent.sky.pastel,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Center(
            child: Icon(
              Icons.biotech_outlined,
              color: AppAccent.sky.vivid,
              size: (height ?? width ?? 48) * 0.55,
            ),
          ),
        ),
      );
    }
    final motif = motifFor(type, category);
    final accent = _accentFor(motif);
    final tile = DecoratedBox(
      decoration: BoxDecoration(
        color: accent.pastel,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: CustomPaint(
        painter: _MotifPainter(motif, accent.vivid),
        child: const SizedBox.expand(),
      ),
    );
    final url = imageUrl;
    return SizedBox(
      width: width,
      height: height,
      child: url == null || url.isEmpty
          ? tile
          : ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => tile,
              ),
            ),
    );
  }
}

class _MotifPainter extends CustomPainter {
  _MotifPainter(this.motif, this.color);

  final ProductMotif motif;
  final Color color;

  static const _white = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    _sparkles(canvas, s);
    switch (motif) {
      case ProductMotif.strip:
        _strip(canvas, s);
      case ProductMotif.bottle:
        _bottle(canvas, s);
      case ProductMotif.syringe:
        _syringe(canvas, s);
      case ProductMotif.tube:
        _tube(canvas, s);
      case ProductMotif.jar:
        _jar(canvas, s);
      case ProductMotif.device:
        _device(canvas, s);
      case ProductMotif.dropper:
        _dropper(canvas, s);
      case ProductMotif.box:
        _box(canvas, s);
      case ProductMotif.capsule:
        _capsule(canvas, s);
    }
    canvas.restore();
  }

  Paint _fill(Color c) => Paint()..color = c;
  Color get _dark => Color.lerp(color, const Color(0xFF12312B), 0.35)!;
  Color get _light => Color.lerp(color, _white, 0.55)!;

  RRect _rr(double cx, double cy, double w, double h, double r) =>
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
        Radius.circular(r),
      );

  void _sparkles(Canvas canvas, double s) {
    final p = _fill(color.withValues(alpha: 0.45));
    canvas.drawCircle(Offset(-s * 0.32, -s * 0.30), s * 0.03, p);
    canvas.drawCircle(Offset(s * 0.34, -s * 0.22), s * 0.02, p);
    canvas.drawCircle(Offset(s * 0.30, s * 0.32), s * 0.035, p);
  }

  void _cross(Canvas canvas, double cx, double cy, double arm, Color c) {
    final p = _fill(c);
    canvas.drawRRect(_rr(cx, cy, arm * 2.4, arm * 0.8, arm * 0.3), p);
    canvas.drawRRect(_rr(cx, cy, arm * 0.8, arm * 2.4, arm * 0.3), p);
  }

  void _strip(Canvas canvas, double s) {
    canvas.rotate(-0.35);
    canvas.drawRRect(_rr(0, 0, s * 0.66, s * 0.44, s * 0.06), _fill(_white));
    canvas.drawRRect(
      _rr(0, 0, s * 0.66, s * 0.44, s * 0.06),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.025
        ..color = _light,
    );
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 3; col++) {
        final o = Offset((col - 1) * s * 0.19, (row - 0.5) * s * 0.19);
        canvas.drawCircle(o, s * 0.065, _fill(row == 0 ? color : _dark));
        canvas.drawCircle(
          o.translate(-s * 0.02, -s * 0.02),
          s * 0.02,
          _fill(_white.withValues(alpha: 0.6)),
        );
      }
    }
  }

  void _bottle(Canvas canvas, double s) {
    canvas.drawRRect(
      _rr(0, s * 0.08, s * 0.34, s * 0.44, s * 0.07),
      _fill(color),
    );
    canvas.drawRRect(
      _rr(0, -s * 0.18, s * 0.16, s * 0.12, s * 0.03),
      _fill(color),
    );
    canvas.drawRRect(
      _rr(0, -s * 0.27, s * 0.22, s * 0.09, s * 0.03),
      _fill(_dark),
    );
    canvas.drawRRect(
      _rr(0, s * 0.1, s * 0.26, s * 0.24, s * 0.04),
      _fill(_white),
    );
    _cross(canvas, 0, s * 0.1, s * 0.06, color);
  }

  void _syringe(Canvas canvas, double s) {
    canvas.rotate(-math.pi / 4);
    canvas.drawRRect(_rr(0, 0, s * 0.2, s * 0.5, s * 0.04), _fill(_white));
    canvas.drawRRect(
      _rr(0, s * 0.07, s * 0.2, s * 0.32, s * 0.03),
      _fill(color),
    );
    canvas.drawRRect(
      _rr(0, -s * 0.26, s * 0.34, s * 0.04, s * 0.02),
      _fill(_dark),
    );
    canvas.drawRRect(
      _rr(0, -s * 0.33, s * 0.06, s * 0.14, s * 0.02),
      _fill(_dark),
    );
    canvas.drawRRect(
      _rr(0, s * 0.27, s * 0.34, s * 0.04, s * 0.02),
      _fill(_dark),
    );
    canvas.drawRRect(
      _rr(0, s * 0.33, s * 0.03, s * 0.12, s * 0.01),
      _fill(_dark),
    );
  }

  void _tube(Canvas canvas, double s) {
    canvas.rotate(-0.4);
    final body = Path()
      ..moveTo(-s * 0.15, -s * 0.2)
      ..lineTo(s * 0.15, -s * 0.2)
      ..lineTo(s * 0.11, s * 0.28)
      ..lineTo(-s * 0.11, s * 0.28)
      ..close();
    canvas.drawPath(body, _fill(color));
    canvas.drawRRect(
      _rr(0, s * 0.29, s * 0.26, s * 0.04, s * 0.01),
      _fill(_dark),
    );
    canvas.drawRRect(
      _rr(0, -s * 0.26, s * 0.2, s * 0.1, s * 0.03),
      _fill(_dark),
    );
    canvas.drawRRect(
      _rr(0, s * 0.03, s * 0.2, s * 0.16, s * 0.03),
      _fill(_white),
    );
    _cross(canvas, 0, s * 0.03, s * 0.04, color);
  }

  void _jar(Canvas canvas, double s) {
    canvas.drawRRect(
      _rr(0, s * 0.06, s * 0.42, s * 0.42, s * 0.08),
      _fill(color),
    );
    canvas.drawRRect(
      _rr(0, -s * 0.2, s * 0.46, s * 0.1, s * 0.04),
      _fill(_dark),
    );
    canvas.drawCircle(Offset(0, s * 0.08), s * 0.12, _fill(_white));
    _cross(canvas, 0, s * 0.08, s * 0.05, color);
  }

  void _device(Canvas canvas, double s) {
    canvas.drawRRect(_rr(0, 0, s * 0.46, s * 0.56, s * 0.09), _fill(_white));
    canvas.drawRRect(
      _rr(0, -s * 0.08, s * 0.34, s * 0.24, s * 0.04),
      _fill(_dark),
    );
    final beat = Path()
      ..moveTo(-s * 0.14, -s * 0.08)
      ..lineTo(-s * 0.06, -s * 0.08)
      ..lineTo(-s * 0.03, -s * 0.16)
      ..lineTo(s * 0.03, -s * 0.0)
      ..lineTo(s * 0.06, -s * 0.08)
      ..lineTo(s * 0.14, -s * 0.08);
    canvas.drawPath(
      beat,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.025
        ..strokeJoin = StrokeJoin.round
        ..color = _white,
    );
    canvas.drawCircle(Offset(0, s * 0.14), s * 0.07, _fill(color));
    canvas.drawCircle(Offset(-s * 0.13, s * 0.14), s * 0.03, _fill(_light));
    canvas.drawCircle(Offset(s * 0.13, s * 0.14), s * 0.03, _fill(_light));
  }

  void _dropper(Canvas canvas, double s) {
    canvas.drawRRect(
      _rr(0, s * 0.1, s * 0.3, s * 0.34, s * 0.07),
      _fill(color),
    );
    canvas.drawRRect(
      _rr(0, -s * 0.1, s * 0.14, s * 0.1, s * 0.02),
      _fill(_dark),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -s * 0.22),
        width: s * 0.16,
        height: s * 0.2,
      ),
      _fill(_dark),
    );
    canvas.drawRRect(
      _rr(0, s * 0.12, s * 0.2, s * 0.16, s * 0.03),
      _fill(_white),
    );
    final drop = Path()
      ..moveTo(s * 0.26, -s * 0.06)
      ..quadraticBezierTo(s * 0.33, s * 0.04, s * 0.26, s * 0.08)
      ..quadraticBezierTo(s * 0.19, s * 0.04, s * 0.26, -s * 0.06);
    canvas.drawPath(drop, _fill(color));
  }

  void _box(Canvas canvas, double s) {
    canvas.drawRRect(_rr(0, 0, s * 0.5, s * 0.4, s * 0.07), _fill(color));
    canvas.drawRRect(
      _rr(0, -s * 0.13, s * 0.5, s * 0.08, s * 0.03),
      _fill(_dark),
    );
    canvas.drawCircle(Offset(0, s * 0.04), s * 0.1, _fill(_white));
    _cross(canvas, 0, s * 0.04, s * 0.045, color);
  }

  void _capsule(Canvas canvas, double s) {
    canvas.rotate(-0.6);
    final w = s * 0.24;
    final h = s * 0.58;
    canvas.save();
    canvas.clipRRect(_rr(0, 0, w, h, w / 2));
    canvas.drawRect(Rect.fromLTWH(-w / 2, -h / 2, w, h / 2), _fill(color));
    canvas.drawRect(Rect.fromLTWH(-w / 2, 0, w, h / 2), _fill(_white));
    canvas.restore();
    canvas.drawRRect(
      _rr(0, 0, w, h, w / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02
        ..color = _dark.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_MotifPainter old) =>
      old.motif != motif || old.color != color;
}
