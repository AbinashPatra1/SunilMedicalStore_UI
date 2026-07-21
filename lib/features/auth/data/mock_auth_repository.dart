import 'package:sunil_medical_store/core/models/app_user.dart';
import 'package:sunil_medical_store/core/models/user_role.dart';
import 'package:sunil_medical_store/features/auth/domain/auth_repository.dart';

/// In-memory mock of [AuthRepository] used until Firebase Authentication is
/// wired up.
///
/// Rules for the mock:
/// * Any password with 6+ characters is accepted.
/// * An email starting with `admin` signs in as [UserRole.admin]; every other
///   email is a [UserRole.customer]. This makes role-based routing testable
///   without a backend.
///
/// The session lives only in memory, so it is not restored across app
/// restarts — that's intentional for the mock.
class MockAuthRepository implements AuthRepository {
  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    // Simulate network latency so loading states are exercised.
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (email.isEmpty || password.isEmpty) {
      throw const AuthException('Email and password are required.');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters.');
    }

    final role = email.toLowerCase().startsWith('admin')
        ? UserRole.admin
        : UserRole.customer;

    final user = AppUser(
      id: 'mock-${email.hashCode.toUnsigned(32)}',
      name: _nameFromEmail(email),
      email: email,
      role: role,
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }

  /// Derives a display name from the local part of an email
  /// (`jane.doe@x.com` -> `Jane Doe`).
  String _nameFromEmail(String email) {
    final local = email.split('@').first.replaceAll(RegExp(r'[._]+'), ' ').trim();
    if (local.isEmpty) return 'User';
    return local
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
