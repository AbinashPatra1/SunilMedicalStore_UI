import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/core/notifications/data/api_fcm_token_repository.dart';
import 'package:sunil_medical_store/core/notifications/domain/fcm_token_repository.dart';
import 'package:sunil_medical_store/core/notifications/in_app_notification_banner.dart';
import 'package:sunil_medical_store/core/notifications/notification_payload.dart';
import 'package:sunil_medical_store/core/routes/app_router.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_controller.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/profile_providers.dart';

final fcmTokenRepositoryProvider = Provider<FcmTokenRepository>((ref) {
  return ApiFcmTokenRepository(ref.watch(dioProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

/// Wires up `firebase_messaging`: requests permission, registers this
/// device's token with the backend, and routes incoming messages — an
/// in-app banner while the app is foregrounded (the OS never shows its own
/// tray notification in that case), a deep-link navigation on tap
/// otherwise. See `docs/API_ENDPOINTS.md` §Push notifications for the
/// message contract (`notification` + `data: {type, id}`) the backend
/// sends.
///
/// [initialize] is idempotent and meant to be called once per authenticated
/// session (from `AuthController`, alongside the profile bootstrap call) —
/// it's cheap to call again (e.g. after sign-out/sign-in) since the listener
/// registration is guarded separately from the token refresh.
class NotificationService {
  NotificationService(this._ref);

  final Ref _ref;
  bool _listenersAttached = false;

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    if (!_listenersAttached) {
      _listenersAttached = true;
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      messaging.onTokenRefresh.listen(_registerToken);

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) _handleNotificationTap(initialMessage);
    }

    final token = await messaging.getToken();
    if (token != null) await _registerToken(token);
  }

  Future<void> _registerToken(String token) async {
    try {
      await _ref.read(fcmTokenRepositoryProvider).register(token);
    } catch (_) {
      // Best-effort — the next app open or token refresh retries.
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    final payload = NotificationPayload.fromData(message.data);
    if (payload != null) _invalidateForPayload(payload);
    showInAppNotificationBanner(
      title: notification.title ?? '',
      body: notification.body ?? '',
      onTap: payload == null ? null : () => _navigate(payload),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final payload = NotificationPayload.fromData(message.data);
    if (payload != null) _navigate(payload);
  }

  void _navigate(NotificationPayload payload) {
    _invalidateForPayload(payload);
    final isAdmin = _ref.read(authControllerProvider).user?.role.isAdmin ?? false;
    final location = payload.resolveRoute(isAdmin: isAdmin);
    if (location != null) _ref.read(routerProvider).push(location);
  }

  /// Invalidates the providers backing the customer order screens so a
  /// status change made elsewhere (the admin console) shows up immediately
  /// instead of only after a manual pull-to-refresh. Called from both the
  /// foreground path (so an already-open Orders list/detail updates live,
  /// even without the user tapping the banner) and the tap/deep-link path
  /// (background/terminated delivery) — invalidating twice for a tapped
  /// foreground banner is a harmless redundant re-fetch, not a bug.
  void _invalidateForPayload(NotificationPayload payload) {
    if (payload.type != NotificationEntityType.order) return;
    _ref.invalidate(pastOrdersProvider);
    _ref.invalidate(orderByIdProvider(payload.id));
  }
}
