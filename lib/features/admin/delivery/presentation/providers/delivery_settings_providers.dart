import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/delivery/data/api_delivery_settings_repository.dart';
import 'package:sunil_medical_store/features/admin/delivery/domain/delivery_settings.dart';
import 'package:sunil_medical_store/features/admin/delivery/domain/delivery_settings_repository.dart';

final deliverySettingsRepositoryProvider = Provider<DeliverySettingsRepository>((ref) {
  return ApiDeliverySettingsRepository(ref.watch(dioProvider));
});

/// Shared by the customer checkout radius-check and the admin settings
/// screen — a `null` value means nothing has been configured yet, so
/// checkout applies no gating rather than blocking every pharmacy order.
final deliverySettingsProvider = FutureProvider<DeliverySettings?>((ref) {
  return ref.watch(deliverySettingsRepositoryProvider).get();
});
