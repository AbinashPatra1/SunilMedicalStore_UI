/// Centralized route path constants, used by [app_router.dart] and by any
/// widget that needs to navigate (`context.go(AppRoutes.cart)`).
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const onboarding = '/onboarding';

  // Admin console — 5-tab shell parallel to the customer area.
  static const admin = '/admin';
  static const adminInventory = '/admin/inventory';
  static const adminInventoryEdit = '/admin/inventory/edit'; // + /<productId>
  static const adminInventoryAdd = '/admin/inventory/new';
  static const adminAppointments = '/admin/appointments';
  static const adminAppointmentEdit = '/admin/appointments/edit'; // + /<id>
  static const adminAppointmentNew = '/admin/appointments/new';
  static const adminDoctors = '/admin/appointments/doctors';
  static const adminDoctorAdd = '/admin/appointments/doctors/new';
  static const adminDoctorEdit = '/admin/appointments/doctors/edit'; // + /<id>
  static const adminOrders = '/admin/orders';
  static const adminOrderEdit = '/admin/orders/edit'; // + /<id>
  static const adminOrderPrescriptionEdit = '/admin/orders/prescriptions/edit'; // + /<id>
  static const adminPathologyEdit = '/admin/orders/pathology/edit'; // + /<id>
  static const adminDiscounts = '/admin/discounts';
  static const adminDiscountEdit = '/admin/discounts/edit'; // + /<id>
  static const adminDiscountAdd = '/admin/discounts/new';
  static const adminMore = '/admin/more';
  static const adminStatistics = '/admin/more/statistics';
  static const adminUsers = '/admin/more/users';
  static const adminUserAdd = '/admin/more/users/new';
  static const adminUserEdit = '/admin/more/users/edit'; // + /<id>

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
  static const search = '/pharmacy/search';
  static const prescriptions = '/pharmacy/prescriptions';

  // Profile sub-sections (nested under the Profile tab).
  static const profileAccount = '/profile/account';
  static const profileAppointments = '/profile/appointments';
  static const profileOrders = '/profile/orders';
  static const profileOrderDetail = '/profile/orders/detail';
  static const profileOrderView = '/profile/orders/view'; // + /<id> — for notification deep links
  static const profileLabTests = '/profile/lab-tests';
  static const profileLabTestDetail = '/profile/lab-tests/detail';
  static const profileAddresses = '/profile/addresses';
  static const profileAddAddress = '/profile/addresses/add';
  static const profilePayments = '/profile/payments';
}
