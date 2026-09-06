import 'package:sunil_medical_store/features/admin/users/domain/admin_user.dart';

/// Directory of all users, admin-only. Used by "book on behalf" pickers and
/// the standalone Admin → More → Users screen (full CRUD).
abstract interface class AdminUsersRepository {
  /// Lists users, optionally narrowed by [query] (matched against name and
  /// phone). Server decides pagination if it needs to; the client currently
  /// doesn't page.
  Future<List<AdminUser>> list({String? query});

  /// Single user by id, for the edit form.
  Future<AdminUser> getById(String id);

  /// Pre-registers a walk-in/phone customer who hasn't signed into the app
  /// yet. [phoneNumber] is the national 10-digit form.
  Future<AdminUser> create({
    required String fullName,
    required String phoneNumber,
    String? email,
  });

  /// Updates [fullName]/[email]. Phone number can't be changed after
  /// creation — it's the account's Firebase login identity.
  Future<AdminUser> update(String id, {required String fullName, String? email});

  /// Throws [ApiException] if the user has any order/appointment/lab-test
  /// history — the backend blocks the delete rather than orphaning it.
  Future<void> delete(String id);
}
