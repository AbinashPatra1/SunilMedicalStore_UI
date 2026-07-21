/// The roles a signed-in user can have.
///
/// Drives role-based navigation (see `app_router.dart`): admins land on the
/// admin area, everyone else on the customer dashboard. Kept in `core` because
/// it's shared by the auth, dashboard, and admin features.
enum UserRole {
  customer,
  admin;

  String get label => switch (this) {
    UserRole.customer => 'Customer',
    UserRole.admin => 'Admin',
  };

  bool get isAdmin => this == UserRole.admin;
}
