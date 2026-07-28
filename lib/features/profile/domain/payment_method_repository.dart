import 'package:sunil_medical_store/features/profile/domain/payment_method.dart';

/// Reads and mutates the caller's saved UPI payment methods, implemented by
/// the data layer. Only UPI is supported.
abstract interface class PaymentMethodRepository {
  Future<List<PaymentMethod>> list();
  Future<PaymentMethod> addUpi(String upiId);
  Future<void> setDefault(String id);
  Future<void> remove(String id);
}
