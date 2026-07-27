/// Centralized route path constants, used by [app_router.dart] and by any
/// widget that needs to navigate (`context.go(AppRoutes.cart)`).
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const onboarding = '/onboarding';

  // Admin area (separate from the customer tab shell).
  static const admin = '/admin';

  // Customer bottom-navigation tabs.
  static const pharmacy = '/pharmacy';
  static const labTests = '/lab-tests';
  static const appointments = '/appointments';
  static const cart = '/cart';
  static const cartCheckout = '/cart/checkout';
  static const profile = '/profile';

  // Nested under the Pharmacy tab so the bottom bar stays visible.
  static const medicines = '/pharmacy/medicines';
  static const medicineDetail = '/pharmacy/medicine'; // + /<productId>

  // Profile sub-sections (nested under the Profile tab).
  static const profileAccount = '/profile/account';
  static const profileAppointments = '/profile/appointments';
  static const profileOrders = '/profile/orders';
  static const profileOrderDetail = '/profile/orders/detail';
  static const profileLabTests = '/profile/lab-tests';
  static const profileLabTestDetail = '/profile/lab-tests/detail';
  static const profileAddresses = '/profile/addresses';
  static const profileAddAddress = '/profile/addresses/add';
  static const profilePayments = '/profile/payments';
}
