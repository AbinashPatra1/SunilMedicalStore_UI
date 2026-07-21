import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_controller.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_state.dart';
import 'package:sunil_medical_store/features/auth/presentation/screens/login_screen.dart';
import 'package:sunil_medical_store/features/cart/presentation/screens/cart_screen.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:sunil_medical_store/features/medicines/presentation/screens/medicines_screen.dart';
import 'package:sunil_medical_store/features/splash/presentation/screens/splash_screen.dart';

/// App-wide [GoRouter] instance.
///
/// The [GoRouter.redirect] callback reads `authControllerProvider` and enforces
/// the whole navigation policy in one place:
/// * `unknown`  -> stay on the splash screen while the session resolves.
/// * signed out -> force the login screen.
/// * signed in  -> land on the role's home (admin vs. customer) and keep
///   non-admins out of the admin area.
///
/// A [ValueNotifier] bumped on every auth change is wired to
/// [GoRouter.refreshListenable] so the redirect re-runs when auth state moves.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshSignal = ValueNotifier<int>(0);
  ref.onDispose(refreshSignal.dispose);
  ref.listen(authControllerProvider, (_, _) => refreshSignal.value++);

  return GoRouter(
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

      // Signed in from here on. Resolve the role's home screen.
      final home = auth.user!.role.isAdmin
          ? AppRoutes.admin
          : AppRoutes.dashboard;

      // Leaving splash/login after auth -> go home.
      if (location == AppRoutes.splash || isLoggingIn) return home;

      // Keep non-admins out of the admin area.
      if (location == AppRoutes.admin && !auth.user!.role.isAdmin) {
        return AppRoutes.dashboard;
      }

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
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.medicines,
        builder: (context, state) => const MedicinesScreen(),
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const CartScreen(),
      ),
    ],
  );
});
