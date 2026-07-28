import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/profile/data/api_profile_repository.dart';
import 'package:sunil_medical_store/features/profile/domain/profile_repository.dart';

/// Provides the [ProfileRepository] implementation.
///
/// Deliberately kept in its own leaf file with no dependency on
/// `features/auth` — `AuthController` reads this provider directly (to
/// bootstrap the backend user row on first sign-in), while
/// `profile_providers.dart` also reads it for the profile screens. Importing
/// `auth_controller.dart` here would create a circular import between the two
/// features.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ApiProfileRepository(ref.watch(dioProvider));
});
