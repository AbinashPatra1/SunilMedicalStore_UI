/// Registers this device's FCM token with the backend so it can receive
/// push notifications (order/appointment/lab-test events — see
/// `docs/API_ENDPOINTS.md` §Push notifications).
abstract interface class FcmTokenRepository {
  /// Upserts [token] for the signed-in user. Safe to call repeatedly (e.g.
  /// on every app start and on token refresh) — the backend keys on the
  /// token itself so re-registering is a no-op if unchanged.
  Future<void> register(String token);
}
