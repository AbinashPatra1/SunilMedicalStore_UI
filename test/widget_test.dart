import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunil_medical_store/app.dart';
import 'package:sunil_medical_store/features/auth/presentation/screens/login_screen.dart';
import 'package:sunil_medical_store/features/splash/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('App shows splash, then redirects an unauthenticated user to login',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // While the (mock) session is resolving, the splash screen is shown.
    expect(find.byType(SplashScreen), findsOneWidget);

    // Let the mock session-restore delay elapse, then settle navigation.
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    // With no saved session, the router redirects to the login screen.
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
