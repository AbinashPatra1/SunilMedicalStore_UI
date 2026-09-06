import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/users/domain/admin_user.dart';
import 'package:sunil_medical_store/features/admin/users/presentation/providers/admin_users_providers.dart';

/// Admin > More > Users > Add / Edit: single form for pre-registering a
/// walk-in customer or editing one. Add mode when [userId] is null.
class AddOrEditAdminUserScreen extends ConsumerWidget {
  const AddOrEditAdminUserScreen({super.key, this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId == null) {
      return const _AdminUserForm(existing: null);
    }
    final async = ref.watch(adminUserByIdProvider(userId!));
    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit user')),
        body: Center(
          child: Text(error is ApiException ? error.message : 'Could not load user.'),
        ),
      ),
      data: (user) => _AdminUserForm(existing: user),
    );
  }
}

class _AdminUserForm extends ConsumerStatefulWidget {
  const _AdminUserForm({required this.existing});

  final AdminUser? existing;

  bool get isEdit => existing != null;

  @override
  ConsumerState<_AdminUserForm> createState() => _AdminUserFormState();
}

class _AdminUserFormState extends ConsumerState<_AdminUserForm> {
  static final _indianMobile = RegExp(r'^[6-9]\d{9}$');
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullName;
  late final TextEditingController _phoneNumber;
  late final TextEditingController _email;

  bool _saving = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = widget.existing;
    _fullName = TextEditingController(text: u?.fullName ?? '');
    _phoneNumber = TextEditingController(text: u?.phoneNumber ?? '');
    _email = TextEditingController(text: u?.email ?? '');
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phoneNumber.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _requiredName(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  String? _validatePhone(String? value) =>
      (value == null || !_indianMobile.hasMatch(value)) ? 'Enter a valid 10-digit mobile number' : null;

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim()) ? null : 'Enter a valid email';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(adminUsersRepositoryProvider);
      final fullName = _fullName.text.trim();
      final email = _email.text.trim().isEmpty ? null : _email.text.trim();
      if (widget.isEdit) {
        await repo.update(widget.existing!.id, fullName: fullName, email: email);
        ref.invalidate(adminUserByIdProvider(widget.existing!.id));
      } else {
        await repo.create(fullName: fullName, phoneNumber: _phoneNumber.text.trim(), email: email);
      }
      ref.invalidate(adminUsersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(widget.isEdit ? 'User updated' : 'User added')));
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!widget.isEdit) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text('This will permanently remove "${widget.existing!.fullName}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(dialogCtx).colorScheme.onErrorContainer,
              backgroundColor: Theme.of(dialogCtx).colorScheme.errorContainer,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await ref.read(adminUsersRepositoryProvider).delete(widget.existing!.id);
      ref.invalidate(adminUsersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('User deleted')));
        context.pop();
      }
    } on ApiException catch (e) {
      // Covers the backend's "block delete if this user has order/
      // appointment/lab-test history" rule — surfaced verbatim here rather
      // than special-cased, same as every other admin delete flow.
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _saving || _deleting;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit user' : 'Add user'),
        actions: [
          if (widget.isEdit)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: busy ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          children: [
            TextFormField(
              controller: _fullName,
              enabled: !busy,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: _requiredName,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _phoneNumber,
              // Phone is the account's Firebase login identity — locking it
              // after creation avoids orphaning the link if this person later
              // signs in with the number they were originally registered
              // under. Same reasoning as locking a promo code's `code`.
              enabled: !busy && !widget.isEdit,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Mobile number',
                prefixText: '+91  ',
                counterText: '',
                helperText: widget.isEdit ? "Can't be changed after creation" : null,
              ),
              validator: _validatePhone,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _email,
              enabled: !busy,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email (optional)'),
              validator: _validateEmail,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppConstants.spacingMd),
              Text(_error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: AppConstants.spacingLg),
            FilledButton(
              onPressed: busy ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.isEdit ? 'Save changes' : 'Add user'),
            ),
          ],
        ),
      ),
    );
  }
}
