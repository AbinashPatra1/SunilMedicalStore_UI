import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/features/auth/presentation/screens/login_screen.dart';
import 'package:sunil_medical_store/features/cart/presentation/screens/cart_screen.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:sunil_medical_store/features/medicines/presentation/screens/medicines_screen.dart';
import 'package:sunil_medical_store/features/splash/presentation/screens/splash_screen.dart';

/// App-wide [GoRouter] instance.
///
/// Exposed as a provider (rather than a bare global) so that later phases
/// can rebuild the router in response to auth state via `refreshListenable`
/// / `redirect`, without touching call sites that read `routerProvider`.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
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
