/// Centralized route path constants, used by [app_router.dart] and by any
/// widget that needs to navigate (`context.go(AppRoutes.cart)`).
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const medicines = '/medicines';
  static const cart = '/cart';
}
