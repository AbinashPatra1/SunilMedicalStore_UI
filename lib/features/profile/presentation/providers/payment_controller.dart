import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/profile/data/api_payment_method_repository.dart';
import 'package:sunil_medical_store/features/profile/domain/payment_method.dart';
import 'package:sunil_medical_store/features/profile/domain/payment_method_repository.dart';

final paymentMethodRepositoryProvider = Provider<PaymentMethodRepository>((ref) {
  return ApiPaymentMethodRepository(ref.watch(dioProvider));
});

/// The customer's saved UPI payment methods. Only UPI is supported.
final paymentMethodsProvider =
    AsyncNotifierProvider<PaymentMethodController, List<PaymentMethod>>(
  PaymentMethodController.new,
);

class PaymentMethodController extends AsyncNotifier<List<PaymentMethod>> {
  PaymentMethodRepository get _repository => ref.read(paymentMethodRepositoryProvider);

  @override
  Future<List<PaymentMethod>> build() => _repository.list();

  Future<void> addUpi(String upiId) async {
    await _repository.addUpi(upiId);
    state = await AsyncValue.guard(() => _repository.list());
  }

  Future<void> setDefault(String id) async {
    await _repository.setDefault(id);
    state = await AsyncValue.guard(() => _repository.list());
  }

  Future<void> remove(String id) async {
    await _repository.remove(id);
    state = await AsyncValue.guard(() => _repository.list());
  }
}
