import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/users/data/api_admin_users_repository.dart';
import 'package:sunil_medical_store/features/admin/users/domain/admin_user.dart';
import 'package:sunil_medical_store/features/admin/users/domain/admin_users_repository.dart';
import 'package:sunil_medical_store/core/paging/paged.dart';

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>((ref) {
  return ApiAdminUsersRepository(ref.watch(dioProvider));
});

/// All users, optionally filtered by [query] (name or phone). Empty string
/// means unfiltered.
final adminUsersProvider =
    FutureProvider.family<List<AdminUser>, String>((ref, query) {
  return ref.watch(adminUsersRepositoryProvider).list(query: query);
});

/// The Users screen's list, paged (numbered pages), optionally filtered by
/// [query]. The appointment "pick a user" sheet keeps the plain
/// [adminUsersProvider] above.
final adminUsersPagedProvider =
    AsyncNotifierProvider.family<AdminUsersPagedNotifier, PagedState<AdminUser>, String>(AdminUsersPagedNotifier.new);

class AdminUsersPagedNotifier extends PagedNotifier<AdminUser> {
  AdminUsersPagedNotifier(this.query);

  final String query;

  @override
  int get pageSize => kAdminPageSize;

  @override
  Future<PagedState<AdminUser>> build() => loadFirst();

  @override
  Future<PageResult<AdminUser>> fetch(int page) =>
      ref.read(adminUsersRepositoryProvider).listPage(query: query, page: page, pageSize: pageSize);

  @override
  Object keyOf(AdminUser item) => item.id;
}

/// A single user for the edit form.
final adminUserByIdProvider = FutureProvider.family<AdminUser, String>((ref, id) {
  return ref.watch(adminUsersRepositoryProvider).getById(id);
});
