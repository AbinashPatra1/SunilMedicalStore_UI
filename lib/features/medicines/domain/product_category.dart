/// The pharmacy's fixed catalog of storefront categories — a client-side
/// enum (not admin-extensible, same "fixed catalog" pattern as `BannerId`)
/// rather than a backend-driven list, since the taxonomy itself is a
/// deliberate, curated set rather than something admins add to freely.
/// `label` is the display string and the exact value sent as `Product`'s
/// `category` field on the wire.
enum ProductCategory {
  vitaminsSupplements,
  monitoringDevices,
  proteinSupplements,
  sexualWellness,
  ayurvedicWellness,
  foodNutrition,
  skinCare,
  menCare,
  womenCare,
  elderlyCare,
  painRelief,
  supportsBraces,
  gutCare,
  diabetes,
  hairCare,
  oralCare,
  coldCoughFever,
  firstAid,
  babyCare,
  respiratoryCare,
  eyeCare,
  prescriptionDrugs;

  String get label => switch (this) {
    ProductCategory.vitaminsSupplements => 'Vitamins & Supplements',
    ProductCategory.monitoringDevices => 'Monitoring Devices',
    ProductCategory.proteinSupplements => 'Protein Supplements',
    ProductCategory.sexualWellness => 'Sexual Wellness',
    ProductCategory.ayurvedicWellness => 'Ayurvedic Wellness',
    ProductCategory.foodNutrition => 'Food & Nutrition',
    ProductCategory.skinCare => 'Skin Care',
    ProductCategory.menCare => 'Men Care',
    ProductCategory.womenCare => 'Women Care',
    ProductCategory.elderlyCare => 'Elderly Care',
    ProductCategory.painRelief => 'Pain Relief',
    ProductCategory.supportsBraces => 'Supports & Braces',
    ProductCategory.gutCare => 'Gut Care',
    ProductCategory.diabetes => 'Diabetes',
    ProductCategory.hairCare => 'Hair Care',
    ProductCategory.oralCare => 'Oral Care',
    ProductCategory.coldCoughFever => 'Cold, Cough & Fever',
    ProductCategory.firstAid => 'First Aid',
    ProductCategory.babyCare => 'Baby Care',
    ProductCategory.respiratoryCare => 'Respiratory Care',
    ProductCategory.eyeCare => 'Eye Care',
    ProductCategory.prescriptionDrugs => 'Prescription Drugs',
  };

  /// Looks up a category by its exact [label] (as returned by the backend
  /// on a `Product`), or `null` if it doesn't match any known category —
  /// e.g. legacy data still using the old pre-redesign taxonomy.
  static ProductCategory? fromLabel(String label) {
    for (final c in ProductCategory.values) {
      if (c.label == label) return c;
    }
    return null;
  }
}

/// Categories featured on the dashboard's "Shop by category" grid, in
/// display order — a curated subset of [ProductCategory.values], not the
/// full catalog. The "Show All Categories" button reveals the rest.
const homeFeaturedCategories = [
  ProductCategory.prescriptionDrugs,
  ProductCategory.vitaminsSupplements,
  ProductCategory.monitoringDevices,
  ProductCategory.proteinSupplements,
  ProductCategory.sexualWellness,
  ProductCategory.ayurvedicWellness,
  ProductCategory.foodNutrition,
  ProductCategory.skinCare,
];

/// Categories shown directly in Admin Inventory's filter bar, before the
/// "more filters" button — the first 5 of the full catalog.
final adminTopBarCategories = ProductCategory.values.take(5).toList(growable: false);
