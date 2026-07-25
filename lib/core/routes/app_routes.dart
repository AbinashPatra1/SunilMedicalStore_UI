/// Centralized route path constants, used by [app_router.dart] and by any
/// widget that needs to navigate (`context.go(AppRoutes.cart)`).
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';

  // Admin area (separate from the customer tab shell).
  static const admin = '/admin';

  // Customer bottom-navigation tabs.
  static const pharmacy = '/pharmacy';
  static const appointments = '/appointments';
  static const cart = '/cart';
  static const profile = '/profile';

  // Nested under the Pharmacy tab so the bottom bar stays visible.
  static const medicines = '/pharmacy/medicines';
}
