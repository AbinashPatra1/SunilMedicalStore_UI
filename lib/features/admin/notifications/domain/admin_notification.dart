import 'package:sunil_medical_store/core/notifications/notification_payload.dart';

/// One entry in the admin's notification inbox — the same event that was
/// pushed to the admin's device (new order, delivered order, new
/// appointment, new lab-test booking, return request), kept server-side so
/// it can be reviewed later. See `docs/API_ENDPOINTS.md` §Admin — Notifications.
class AdminNotification {
  const AdminNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.type,
    this.entityId,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  /// What [entityId] refers to; `null` when the backend sent a type this app
  /// doesn't know (the row then just isn't tappable).
  final NotificationEntityType? type;
  final String? entityId;
  final bool isRead;

  /// The screen this notification opens, or `null` if it has no target.
  String? get route {
    final t = type;
    final id = entityId;
    if (t == null || id == null) return null;
    return NotificationPayload(type: t, id: id).resolveRoute(isAdmin: true);
  }

  static AdminNotification fromJson(Map<String, dynamic> json) {
    NotificationEntityType? type;
    for (final t in NotificationEntityType.values) {
      if (t.name == json['type']) type = t;
    }
    return AdminNotification(
      id: json['id'].toString(),
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      type: type,
      entityId: json['entityId']?.toString(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}
