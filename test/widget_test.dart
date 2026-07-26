import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunil_medical_store/app.dart';
import 'package:sunil_medical_store/features/auth/domain/auth_account.dart';
import 'package:sunil_medical_store/features/auth/domain/auth_repository.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_controller.dart';
import 'package:sunil_medical_store/features/auth/presentation/screens/login_screen.dart';
import 'package:sunil_medical_store/features/splash/presentation/screens/splash_screen.dart';

/// Signed-out fake so the test never touches Firebase.
class _SignedOutAuthRepository implements AuthRepository {
  @override
  Stream<AuthAccount?> authStateChanges() => Stream.value(null);

  @override
  Future<String> sendOtp({required String phoneNumber}) async => 'test-id';

  @override
  Future<void> verifyOtp({required String verificationId, required String smsCode}) async {}

  @override
  Future<AuthAccount> completeProfile({required String fullName}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('App shows splash, then redirects a signed-out user to login',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_SignedOutAuthRepository()),
        ],
        child: const MyApp(),
      ),
    );

    // While the session is resolving, the splash screen is shown.
    expect(find.byType(SplashScreen), findsOneWidget);

    // The stream emits "signed out"; the router redirects to login.
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
