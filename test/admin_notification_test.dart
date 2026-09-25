import 'package:flutter_test/flutter_test.dart';
import 'package:sunil_medical_store/core/notifications/notification_payload.dart';
import 'package:sunil_medical_store/features/admin/notifications/domain/admin_notification.dart';

void main() {
  test('exact and event-specific types resolve to a screen family', () {
    expect(parseNotificationType('order'), NotificationEntityType.order);
    expect(parseNotificationType('labTest'), NotificationEntityType.labTest);
    expect(parseNotificationType('return_requested'), NotificationEntityType.order);
    expect(parseNotificationType('new_appointment'), NotificationEntityType.appointment);
    expect(parseNotificationType('lab_test_booked'), NotificationEntityType.labTest);
    expect(parseNotificationType('mystery'), isNull);
    expect(parseNotificationType(null), isNull);
  });

  test('a return-requested notification opens the admin order', () {
    final n = AdminNotification.fromJson({
      'id': 'n1',
      'type': 'return_requested',
      'entityId': 'o9',
      'title': 'Return requested',
      'body': '',
      'createdAt': '2026-09-25T15:05:35Z',
      'isRead': false,
    });
    expect(n.route, '/admin/orders/edit/o9');
  });
}
