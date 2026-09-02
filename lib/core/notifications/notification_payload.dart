import 'package:sunil_medical_store/core/routes/app_routes.dart';

/// What a push notification's `data` payload refers to. Wire values match
/// the backend's `type` field exactly (see `docs/API_ENDPOINTS.md` §Push
/// notifications) — lowerCamelCase, same convention as every other enum in
/// this app.
enum NotificationEntityType { order, appointment, labTest }

/// Parsed `data` payload of an incoming [RemoteMessage], used to route a
/// notification tap to the right screen.
class NotificationPayload {
  const NotificationPayload({required this.type, required this.id});

  final NotificationEntityType type;
  final String id;

  /// Returns `null` if [data] doesn't look like a notification this app
  /// knows how to route (missing/unrecognized `type`, missing `id`) —
  /// callers should just do nothing rather than crash on a malformed or
  /// future-versioned payload.
  static NotificationPayload? fromData(Map<String, dynamic> data) {
    final id = data['id'] as String?;
    final typeName = data['type'] as String?;
    if (id == null || typeName == null) return null;

    for (final type in NotificationEntityType.values) {
      if (type.name == typeName) return NotificationPayload(type: type, id: id);
    }
    return null;
  }

  /// The route to open for this notification, given whether the current
  /// signed-in user is an admin. `null` means "just open the app" — used
  /// where no matching detail screen exists yet (admin lab-test bookings
  /// have no dedicated review screen).
  String? resolveRoute({required bool isAdmin}) {
    switch (type) {
      case NotificationEntityType.order:
        return isAdmin ? '${AppRoutes.adminOrderEdit}/$id' : '${AppRoutes.profileOrderView}/$id';
      case NotificationEntityType.appointment:
        return isAdmin ? '${AppRoutes.adminAppointmentEdit}/$id' : AppRoutes.profileAppointments;
      case NotificationEntityType.labTest:
        // No admin lab-test-booking screen exists yet — land on Orders,
        // the closest related admin surface, rather than nothing.
        return isAdmin ? AppRoutes.adminOrders : AppRoutes.profileLabTests;
    }
  }
}
