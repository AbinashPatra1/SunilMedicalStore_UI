import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/users/data/api_admin_users_repository.dart';
import 'package:sunil_medical_store/features/admin/users/domain/admin_user.dart';
import 'package:sunil_medical_store/features/admin/users/domain/admin_users_repository.dart';

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>((ref) {
  return ApiAdminUsersRepository(ref.watch(dioProvider));
});

/// All users, optionally filtered by [query] (name or phone). Empty string
/// means unfiltered.
final adminUsersProvider =
    FutureProvider.family<List<AdminUser>, String>((ref, query) {
  return ref.watch(adminUsersRepositoryProvider).list(query: query);
});

/// A single user for the edit form.
final adminUserByIdProvider = FutureProvider.family<AdminUser, String>((ref, id) {
  return ref.watch(adminUsersRepositoryProvider).getById(id);
});
