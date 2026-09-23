import 'package:sunil_medical_store/features/admin/notifications/domain/admin_notification.dart';

/// The admin's notification inbox.
abstract interface class AdminNotificationRepository {
  /// Notifications, newest first.
  Future<List<AdminNotification>> list();

  Future<void> markRead(String id);

  Future<void> markAllRead();
}
