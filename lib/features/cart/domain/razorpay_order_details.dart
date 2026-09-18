/// Result of `POST /payments/razorpay/order` (`docs/API_ENDPOINTS.md` #80):
/// everything the client needs to open Razorpay's checkout SDK for the
/// authoritatively-priced cart. [keyId] is the Razorpay *public* key — sourced
/// from the backend response rather than bundled in the app, so switching
/// between test/live mode never needs a client release.
class RazorpayOrderDetails {
  const RazorpayOrderDetails({
    required this.razorpayOrderId,
    required this.amount,
    required this.currency,
    required this.keyId,
  });

  final String razorpayOrderId;

  /// Smallest currency unit (paise for INR), per Razorpay's convention.
  final int amount;
  final String currency;
  final String keyId;
}
