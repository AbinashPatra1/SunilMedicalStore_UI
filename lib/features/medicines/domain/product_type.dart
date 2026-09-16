/// How a product is dispensed/administered — a new, admin-set
/// classification alongside [ProductCategory], used by Admin Inventory's
/// filter/search. Nullable on `Product` (built ahead of the backend, see
/// `docs/API_ENDPOINTS.md`) so existing/legacy products without one degrade
/// cleanly rather than crash.
enum ProductType {
  tabletDrug,
  liquidDrug,
  injection,
  nonOralDrug,
  others;

  String get label => switch (this) {
    ProductType.tabletDrug => 'Tablet Drug',
    ProductType.liquidDrug => 'Liquid Drug',
    ProductType.injection => 'Injection',
    ProductType.nonOralDrug => 'Non Oral Drug',
    ProductType.others => 'Others',
  };

  static ProductType? fromWireName(String? name) {
    if (name == null) return null;
    for (final t in ProductType.values) {
      if (t.name == name) return t;
    }
    return null;
  }
}
