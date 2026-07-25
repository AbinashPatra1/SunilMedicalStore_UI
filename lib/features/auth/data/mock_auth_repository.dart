import 'package:sunil_medical_store/core/models/app_user.dart';
import 'package:sunil_medical_store/core/models/user_role.dart';
import 'package:sunil_medical_store/features/auth/domain/auth_repository.dart';

/// In-memory mock of [AuthRepository] used until Firebase Phone
/// Authentication is wired up.
///
/// Rules for the mock:
/// * The phone number must be a valid 10-digit Indian mobile number
///   (starts with 6-9).
/// * The OTP is always [_mockOtp] (`123456`).
/// * The number [_adminPhone] (`9999999999`) signs in as [UserRole.admin];
///   every other number is a [UserRole.customer]. This makes role-based
///   routing testable without a backend.
///
/// The session lives only in memory, so it is not restored across app
/// restarts — that's intentional for the mock.
class MockAuthRepository implements AuthRepository {
  static const _mockOtp = '123456';
  static const _adminPhone = '9999999999';
  static const _verificationPrefix = 'mock-verification:';

  static final _indianMobile = RegExp(r'^[6-9]\d{9}$');

  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<String> sendOtp({required String phoneNumber}) async {
    // Simulate the network round-trip of requesting an SMS.
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (!_indianMobile.hasMatch(phoneNumber)) {
      throw const AuthException('Enter a valid 10-digit mobile number.');
    }

    // The phone is encoded into the verification id so that verifyOtp can
    // recover it, mirroring how a real backend ties the two calls together.
    return '$_verificationPrefix$phoneNumber';
  }

  @override
  Future<AppUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (smsCode != _mockOtp) {
      throw const AuthException('Incorrect OTP. Use $_mockOtp for the demo.');
    }
    if (!verificationId.startsWith(_verificationPrefix)) {
      throw const AuthException('Verification expired. Request a new OTP.');
    }

    final phoneNumber = verificationId.substring(_verificationPrefix.length);
    final role = phoneNumber == _adminPhone
        ? UserRole.admin
        : UserRole.customer;

    final user = AppUser(
      id: 'mock-$phoneNumber',
      name: role.isAdmin ? 'Admin' : 'Customer',
      phoneNumber: phoneNumber,
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
}
