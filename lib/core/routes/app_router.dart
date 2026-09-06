import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/widgets/admin_scaffold_with_nav_bar.dart';
import 'package:sunil_medical_store/core/widgets/scaffold_with_nav_bar.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/screens/add_or_edit_doctor_screen.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/screens/admin_appointments_screen.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/screens/create_appointment_screen.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/screens/edit_appointment_screen.dart';
import 'package:sunil_medical_store/features/admin/discounts/presentation/screens/add_or_edit_promo_code_screen.dart';
import 'package:sunil_medical_store/features/admin/discounts/presentation/screens/discounts_list_screen.dart';
import 'package:sunil_medical_store/features/admin/inventory/presentation/screens/add_or_edit_product_screen.dart';
import 'package:sunil_medical_store/features/admin/inventory/presentation/screens/inventory_list_screen.dart';
import 'package:sunil_medical_store/features/admin/more/presentation/screens/admin_more_screen.dart';
import 'package:sunil_medical_store/features/admin/orders/presentation/screens/admin_order_detail_screen.dart';
import 'package:sunil_medical_store/features/admin/orders/presentation/screens/admin_orders_screen.dart';
import 'package:sunil_medical_store/features/admin/orders/presentation/screens/admin_prescription_detail_screen.dart';
import 'package:sunil_medical_store/features/admin/statistics/presentation/screens/admin_statistics_screen.dart';
import 'package:sunil_medical_store/features/admin/users/presentation/screens/add_or_edit_admin_user_screen.dart';
import 'package:sunil_medical_store/features/admin/users/presentation/screens/admin_users_list_screen.dart';
import 'package:sunil_medical_store/features/appointments/presentation/screens/appointments_screen.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_controller.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_state.dart';
import 'package:sunil_medical_store/features/auth/presentation/screens/login_screen.dart';
import 'package:sunil_medical_store/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:sunil_medical_store/features/cart/presentation/screens/cart_screen.dart';
import 'package:sunil_medical_store/features/cart/presentation/screens/checkout_screen.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:sunil_medical_store/features/lab_tests/presentation/screens/lab_test_catalog_detail_screen.dart';
import 'package:sunil_medical_store/features/lab_tests/presentation/screens/lab_tests_catalog_screen.dart';
import 'package:sunil_medical_store/features/medicines/presentation/screens/medicine_detail_screen.dart';
import 'package:sunil_medical_store/features/medicines/presentation/screens/medicines_screen.dart';
import 'package:sunil_medical_store/features/medicines/presentation/screens/search_screen.dart';
import 'package:sunil_medical_store/features/prescriptions/presentation/screens/prescriptions_screen.dart';
import 'package:sunil_medical_store/features/profile/domain/lab_test.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/features/profile/presentation/screens/account_screen.dart';
import 'package:sunil_medical_store/features/profile/presentation/screens/add_address_screen.dart';
import 'package:sunil_medical_store/features/profile/presentation/screens/addresses_screen.dart';
import 'package:sunil_medical_store/features/profile/presentation/screens/lab_test_detail_screen.dart';
import 'package:sunil_medical_store/features/profile/presentation/screens/lab_tests_screen.dart';
import 'package:sunil_medical_store/features/profile/presentation/screens/order_detail_by_id_screen.dart';
import 'package:sunil_medical_store/features/profile/presentation/screens/order_detail_screen.dart';
import 'package:sunil_medical_store/features/profile/presentation/screens/orders_screen.dart';
import 'package:sunil_medical_store/features/profile/presentation/screens/payment_methods_screen.dart';
import 'package:sunil_medical_store/features/profile/presentation/screens/profile_appointments_screen.dart';
import 'package:sunil_medical_store/features/profile/presentation/screens/profile_screen.dart';
import 'package:sunil_medical_store/features/splash/presentation/screens/splash_screen.dart';

/// App-wide [GoRouter] instance.
///
/// The [GoRouter.redirect] callback reads `authControllerProvider` and enforces
/// the whole navigation policy in one place:
/// * `unknown`  -> stay on the splash screen while the session resolves.
/// * signed out -> force the login screen.
/// * signed in  -> land on the role's home (admin console vs. customer tabs)
///   and keep each role out of the other's area.
///
/// The four customer tabs live in a [StatefulShellRoute.indexedStack] so each
/// keeps its own navigation stack and state; the admin console is a separate
/// top-level route with no bottom navigation.
///
/// The admin console lives in its own five-tab [StatefulShellRoute] parallel
/// to the customer shell — same navigation pattern, disjoint route trees.
///
/// A [ValueNotifier] bumped on every auth change is wired to
/// [GoRouter.refreshListenable] so the redirect re-runs when auth state moves.
/// The app's single root [Navigator], exposed so code outside the widget
/// tree (the in-app push-notification banner) can insert an [OverlayEntry]
/// without needing a [BuildContext] of its own.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refreshSignal = ValueNotifier<int>(0);
  ref.onDispose(refreshSignal.dispose);
  ref.listen(authControllerProvider, (_, _) => refreshSignal.value++);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refreshSignal,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      // Session not resolved yet: hold on the splash screen.
      if (auth.status == AuthStatus.unknown) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isLoggingIn = location == AppRoutes.login;

      // Signed out: only the login screen is reachable.
      if (auth.status == AuthStatus.unauthenticated) {
        return isLoggingIn ? null : AppRoutes.login;
      }

      // Verified but no profile yet: force the onboarding screen.
      if (auth.status == AuthStatus.onboarding) {
        return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      // Signed in from here on. Resolve the role's home.
      final isAdmin = auth.user!.role.isAdmin;
      final home = isAdmin ? AppRoutes.adminInventory : AppRoutes.pharmacy;

      // Leaving splash/login/onboarding after auth -> go home.
      if (location == AppRoutes.splash ||
          isLoggingIn ||
          location == AppRoutes.onboarding) {
        return home;
      }

      // Keep each role inside its own area. Admin routes live under /admin;
      // everything else is customer.
      final inAdminArea = location.startsWith(AppRoutes.admin);
      if (isAdmin && !inAdminArea) return AppRoutes.adminInventory;
      if (!isAdmin && inAdminArea) return AppRoutes.pharmacy;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Admin tab shell (parallel to customer shell).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminInventory,
                builder: (context, state) => const InventoryListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const AddOrEditProductScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:productId',
                    builder: (context, state) => AddOrEditProductScreen(
                      productId: state.pathParameters['productId'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminAppointments,
                builder: (context, state) => const AdminAppointmentsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const CreateAppointmentScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    builder: (context, state) => EditAppointmentScreen(
                      appointmentId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'doctors/new',
                    builder: (context, state) => const AddOrEditDoctorScreen(),
                  ),
                  GoRoute(
                    path: 'doctors/edit/:id',
                    builder: (context, state) => AddOrEditDoctorScreen(
                      doctorId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminOrders,
                builder: (context, state) => const AdminOrdersScreen(),
                routes: [
                  GoRoute(
                    path: 'edit/:id',
                    builder: (context, state) => AdminOrderDetailScreen(
                      orderId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'prescriptions/edit/:id',
                    builder: (context, state) => AdminPrescriptionDetailScreen(
                      prescriptionId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminDiscounts,
                builder: (context, state) => const DiscountsListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const AddOrEditPromoCodeScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    builder: (context, state) => AddOrEditPromoCodeScreen(
                      promoCodeId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminMore,
                builder: (context, state) => const AdminMoreScreen(),
                routes: [
                  GoRoute(
                    path: 'statistics',
                    builder: (context, state) => const AdminStatisticsScreen(),
                  ),
                  GoRoute(
                    path: 'users',
                    builder: (context, state) => const AdminUsersListScreen(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (context, state) => const AddOrEditAdminUserScreen(),
                      ),
                      GoRoute(
                        path: 'edit/:id',
                        builder: (context, state) => AddOrEditAdminUserScreen(
                          userId: state.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Customer tab shell.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.pharmacy,
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  // Nested -> /pharmacy/medicines (bottom bar stays visible).
                  // Optional ?category= filters the list.
                  GoRoute(
                    path: 'medicines',
                    builder: (context, state) => MedicinesScreen(
                      category: state.uri.queryParameters['category'],
                    ),
                  ),
                  // Product detail (sibling of the list so it pushes cleanly
                  // from both the list and the dashboard).
                  GoRoute(
                    path: 'medicine/:productId',
                    builder: (context, state) => MedicineDetailScreen(
                      productId: state.pathParameters['productId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'prescriptions',
                    builder: (context, state) => const PrescriptionsScreen(),
                  ),
                  GoRoute(
                    path: 'search',
                    builder: (context, state) => const SearchScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.labTests,
                builder: (context, state) => const LabTestsCatalogScreen(),
                routes: [
                  GoRoute(
                    path: ':testId',
                    builder: (context, state) => LabTestCatalogDetailScreen(
                      testId: state.pathParameters['testId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.appointments,
                builder: (context, state) => const AppointmentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                builder: (context, state) => const CartScreen(),
                routes: [
                  GoRoute(
                    path: 'checkout',
                    builder: (context, state) => const CheckoutScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(path: 'account', builder: (context, state) => const AccountScreen()),
                  GoRoute(path: 'appointments', builder: (context, state) => const ProfileAppointmentsScreen()),
                  GoRoute(
                    path: 'orders',
                    builder: (context, state) => const OrdersScreen(),
                    routes: [
                      GoRoute(
                        path: 'detail',
                        builder: (context, state) => OrderDetailScreen(order: state.extra as Order?),
                      ),
                      GoRoute(
                        path: 'view/:id',
                        builder: (context, state) => OrderDetailByIdScreen(
                          orderId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'lab-tests',
                    builder: (context, state) => const LabTestsScreen(),
                    routes: [
                      GoRoute(
                        path: 'detail',
                        builder: (context, state) => LabTestDetailScreen(labTest: state.extra as LabTest?),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'addresses',
                    builder: (context, state) => const AddressesScreen(),
                    routes: [
                      GoRoute(path: 'add', builder: (context, state) => const AddAddressScreen()),
                    ],
                  ),
                  GoRoute(path: 'payments', builder: (context, state) => const PaymentMethodsScreen()),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
