import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/features/profile/domain/payment_method.dart';

/// Holds the customer's saved payment methods in memory. Only UPI is supported
/// for now.
final paymentMethodsProvider =
    NotifierProvider<PaymentMethodController, List<PaymentMethod>>(
  PaymentMethodController.new,
);

class PaymentMethodController extends Notifier<List<PaymentMethod>> {
  var _seq = 0;

  @override
  List<PaymentMethod> build() => const [];

  /// Adds a UPI id. The first method added becomes the default.
  void addUpi(String upiId) {
    final becomesDefault = state.isEmpty;
    final method = PaymentMethod(
      id: 'pm-${_seq++}',
      upiId: upiId,
      isDefault: becomesDefault,
    );
    final base = becomesDefault
        ? state.map((m) => m.copyWith(isDefault: false)).toList()
        : List<PaymentMethod>.from(state);
    state = [...base, method];
  }

  void setDefault(String id) {
    state = [for (final m in state) m.copyWith(isDefault: m.id == id)];
  }

  void remove(String id) {
    state = state.where((m) => m.id != id).toList();
  }
}
