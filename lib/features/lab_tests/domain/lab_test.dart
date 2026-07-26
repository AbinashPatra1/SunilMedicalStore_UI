/// A bookable lab test in the catalog.
///
/// Distinct from `profile/domain/lab_test.dart`, which models a test the user
/// has already booked (with a status/date). This one is the storefront item.
class LabTest {
  const LabTest({
    required this.id,
    required this.name,
    required this.description,
    required this.labName,
    required this.price,
    this.mrp,
    required this.sampleType,
    required this.reportTime,
    required this.fastingRequired,
    required this.parameters,
  });

  final String id;
  final String name;
  final String description;
  final String labName;

  /// Price in rupees.
  final int price;

  /// Pre-discount price in rupees, when discounted.
  final int? mrp;

  /// e.g. `Blood`, `Urine`, `Blood & Urine`.
  final String sampleType;

  /// e.g. `Within 24 hours`.
  final String reportTime;
  final bool fastingRequired;

  /// The individual parameters covered by the test.
  final List<String> parameters;

  int? get discountPercent {
    final m = mrp;
    if (m == null || m <= price) return null;
    return (((m - price) / m) * 100).round();
  }
}
