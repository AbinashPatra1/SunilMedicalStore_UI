import 'package:sunil_medical_store/features/admin/delivery/domain/delivery_settings.dart';

/// Reads the store's delivery-radius configuration (any signed-in user, so
/// the customer app can gate pharmacy checkout) and lets an admin update it.
abstract interface class DeliverySettingsRepository {
  /// `null` if nothing has been configured yet — callers should treat that
  /// as "no gating", not an error.
  Future<DeliverySettings?> get();

  Future<DeliverySettings> update({
    required double storeLatitude,
    required double storeLongitude,
    required double radiusKm,
  });
}
