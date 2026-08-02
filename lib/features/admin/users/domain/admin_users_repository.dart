import 'package:sunil_medical_store/features/admin/users/domain/admin_user.dart';

/// Read-only directory of all users, admin-only. Used by "book on behalf"
/// pickers today; the Statistics tab will reuse the same repository.
abstract interface class AdminUsersRepository {
  /// Lists users, optionally narrowed by [query] (matched against name and
  /// phone). Server decides pagination if it needs to; the client currently
  /// doesn't page.
  Future<List<AdminUser>> list({String? query});
}
