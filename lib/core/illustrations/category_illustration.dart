import 'package:flutter/material.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_category.dart';

/// A colorful, layered flat-style illustration for a storefront category —
/// a pastel card, a soft color blob, a vivid icon badge, and a couple of
/// sparkle accents. Not literal photography (see backlog #14: this app
/// deliberately has no external asset/SVG pipeline), but aims for the same
/// "colorful product card" read as real product photography on a tinted
/// background, entirely via `CustomPainter` like the rest of this app's
/// illustration set.
class CategoryIllustration extends StatelessWidget {
  const CategoryIllustration({super.key, required this.category, this.size = 64});

  final ProductCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CategoryPainter(_specFor(category))),
    );
  }
}

class _CategorySpec {
  const _CategorySpec({required this.cardColor, required this.badgeColor, required this.icon});

  final Color cardColor;
  final Color badgeColor;
  final IconData icon;
}

_CategorySpec _specFor(ProductCategory category) => switch (category) {
  ProductCategory.vitaminsSupplements => const _CategorySpec(
    cardColor: Color(0xFFFFF3D6),
    badgeColor: Color(0xFFF2A93B),
    icon: Icons.medication_outlined,
  ),
  ProductCategory.monitoringDevices => const _CategorySpec(
    cardColor: Color(0xFFE3E9FF),
    badgeColor: Color(0xFF5B6DF2),
    icon: Icons.monitor_heart_outlined,
  ),
  ProductCategory.proteinSupplements => const _CategorySpec(
    cardColor: Color(0xFFE7E2FB),
    badgeColor: Color(0xFF8B5CF6),
    icon: Icons.fitness_center,
  ),
  ProductCategory.sexualWellness => const _CategorySpec(
    cardColor: Color(0xFFFCE1EC),
    badgeColor: Color(0xFFEF5B9C),
    icon: Icons.favorite_outline,
  ),
  ProductCategory.ayurvedicWellness => const _CategorySpec(
    cardColor: Color(0xFFE1F3E1),
    badgeColor: Color(0xFF3FA35B),
    icon: Icons.eco_outlined,
  ),
  ProductCategory.foodNutrition => const _CategorySpec(
    cardColor: Color(0xFFFFE8D6),
    badgeColor: Color(0xFFEF8C3C),
    icon: Icons.restaurant_outlined,
  ),
  ProductCategory.skinCare => const _CategorySpec(
    cardColor: Color(0xFFFDE7EF),
    badgeColor: Color(0xFFE0679A),
    icon: Icons.face_retouching_natural,
  ),
  ProductCategory.menCare => const _CategorySpec(
    cardColor: Color(0xFFE4ECF7),
    badgeColor: Color(0xFF3E6FA8),
    icon: Icons.face_outlined,
  ),
  ProductCategory.womenCare => const _CategorySpec(
    cardColor: Color(0xFFFCE3F0),
    badgeColor: Color(0xFFD65AA8),
    icon: Icons.local_florist_outlined,
  ),
  ProductCategory.elderlyCare => const _CategorySpec(
    cardColor: Color(0xFFEFE6D9),
    badgeColor: Color(0xFF9A7B4F),
    icon: Icons.elderly_outlined,
  ),
  ProductCategory.painRelief => const _CategorySpec(
    cardColor: Color(0xFFFDE3E1),
    badgeColor: Color(0xFFE0563F),
    icon: Icons.healing_outlined,
  ),
  ProductCategory.supportsBraces => const _CategorySpec(
    cardColor: Color(0xFFE6ECEF),
    badgeColor: Color(0xFF5C7A8A),
    icon: Icons.accessibility_new_outlined,
  ),
  ProductCategory.gutCare => const _CategorySpec(
    cardColor: Color(0xFFFFF0DE),
    badgeColor: Color(0xFFD98A3D),
    icon: Icons.grain_outlined,
  ),
  ProductCategory.diabetes => const _CategorySpec(
    cardColor: Color(0xFFFBE2E2),
    badgeColor: Color(0xFFD8434B),
    icon: Icons.bloodtype_outlined,
  ),
  ProductCategory.hairCare => const _CategorySpec(
    cardColor: Color(0xFFF0E6F7),
    badgeColor: Color(0xFF9757B0),
    icon: Icons.content_cut_outlined,
  ),
  ProductCategory.oralCare => const _CategorySpec(
    cardColor: Color(0xFFDFF5F1),
    badgeColor: Color(0xFF2FA79A),
    icon: Icons.sentiment_satisfied_outlined,
  ),
  ProductCategory.coldCoughFever => const _CategorySpec(
    cardColor: Color(0xFFFFE9D9),
    badgeColor: Color(0xFFE8823C),
    icon: Icons.thermostat_outlined,
  ),
  ProductCategory.firstAid => const _CategorySpec(
    cardColor: Color(0xFFFBE0E0),
    badgeColor: Color(0xFFE0433F),
    icon: Icons.medical_services_outlined,
  ),
  ProductCategory.babyCare => const _CategorySpec(
    cardColor: Color(0xFFFFF1DC),
    badgeColor: Color(0xFFF0A93F),
    icon: Icons.child_care_outlined,
  ),
  ProductCategory.respiratoryCare => const _CategorySpec(
    cardColor: Color(0xFFDFEFFB),
    badgeColor: Color(0xFF3B9BD6),
    icon: Icons.air_outlined,
  ),
  ProductCategory.eyeCare => const _CategorySpec(
    cardColor: Color(0xFFE4E8FC),
    badgeColor: Color(0xFF5A66C4),
    icon: Icons.remove_red_eye_outlined,
  ),
  ProductCategory.prescriptionDrugs => const _CategorySpec(
    cardColor: Color(0xFFC9ECE0),
    badgeColor: Color(0xFF2E8B6F),
    icon: Icons.local_pharmacy_outlined,
  ),
  ProductCategory.others => const _CategorySpec(
    cardColor: Color(0xFFEDEFF2),
    badgeColor: Color(0xFF6B7280),
    icon: Icons.category_outlined,
  ),
};

class _CategoryPainter extends CustomPainter {
  _CategoryPainter(this.spec);

  final _CategorySpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Pastel rounded-square card, matching the reference composition.
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.22),
    );
    canvas.drawRRect(cardRect, Paint()..color = spec.cardColor);

    final center = Offset(w * 0.5, h * 0.5);

    // Soft blob behind the badge for depth.
    canvas.drawCircle(center, w * 0.4, Paint()..color = spec.badgeColor.withValues(alpha: 0.18));

    // Vivid icon badge — the main "product" visual.
    canvas.drawCircle(center, w * 0.3, Paint()..color = spec.badgeColor);
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(spec.icon.codePoint),
        style: TextStyle(
          fontSize: w * 0.32,
          fontFamily: spec.icon.fontFamily,
          package: spec.icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));

    // Sparkle accents for a bit of life/sheen.
    final sparklePaint = Paint()..color = spec.badgeColor.withValues(alpha: 0.7);
    _sparkle(canvas, Offset(w * 0.16, h * 0.18), w * 0.05, sparklePaint);
    _sparkle(canvas, Offset(w * 0.85, h * 0.78), w * 0.035, sparklePaint);
  }

  void _sparkle(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.28, c.dy - r * 0.28)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx + r * 0.28, c.dy + r * 0.28)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r * 0.28, c.dy + r * 0.28)
      ..lineTo(c.dx - r, c.dy)
      ..lineTo(c.dx - r * 0.28, c.dy - r * 0.28)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CategoryPainter oldDelegate) => oldDelegate.spec != spec;
}
