/// What kind of catalog item a cart line represents.
enum CartItemKind { medicine, labTest }

/// A line in the cart. Holds denormalized fields (a snapshot of the catalog
/// item) rather than a reference, so medicines and lab tests can share the
/// cart without coupling it to either catalog's domain model.
class CartItem {
  const CartItem({
    required this.id,
    required this.catalogId,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.kind,
    required this.quantity,
    this.requiresPrescription = false,
  });

  /// Unique within the cart (kind-prefixed, e.g. `medicine-p1`, `labtest-lt2`).
  final String id;

  /// The raw catalog id (`p1`, `lt2`) — what the orders API expects as
  /// `productId`/`testId`, as opposed to [id] which is cart-local.
  final String catalogId;

  final String title;

  /// Brand (medicine) or lab name (lab test).
  final String subtitle;

  /// Unit price in rupees.
  final int price;
  final CartItemKind kind;
  final int quantity;

  /// Whether this line requires a prescription — always `false` for lab
  /// tests, mirrors `Product.requiresPrescription` for medicines.
  final bool requiresPrescription;

  int get lineTotal => price * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
    id: id,
    catalogId: catalogId,
    title: title,
    subtitle: subtitle,
    price: price,
    kind: kind,
    quantity: quantity ?? this.quantity,
    requiresPrescription: requiresPrescription,
  );
}
