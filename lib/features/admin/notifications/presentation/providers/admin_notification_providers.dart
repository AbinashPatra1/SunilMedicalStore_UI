import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/notifications/data/api_admin_notification_repository.dart';
import 'package:sunil_medical_store/features/admin/notifications/domain/admin_notification.dart';
import 'package:sunil_medical_store/features/admin/notifications/domain/admin_notification_repository.dart';

final adminNotificationRepositoryProvider = Provider<AdminNotificationRepository>((ref) {
  return ApiAdminNotificationRepository(ref.watch(dioProvider));
});

/// The admin's notification inbox, newest first.
final adminNotificationsProvider = FutureProvider<List<AdminNotification>>((ref) {
  return ref.watch(adminNotificationRepositoryProvider).list();
});
