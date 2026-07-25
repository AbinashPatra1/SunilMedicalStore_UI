/// A saved payment method. Only UPI is supported for now.
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.upiId,
    this.isDefault = false,
  });

  final String id;

  /// The UPI VPA, e.g. `name@bank`.
  final String upiId;
  final bool isDefault;

  PaymentMethod copyWith({bool? isDefault}) {
    return PaymentMethod(
      id: id,
      upiId: upiId,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
