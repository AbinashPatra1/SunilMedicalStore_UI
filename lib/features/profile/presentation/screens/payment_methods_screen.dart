import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_palette.dart';
import 'package:sunil_medical_store/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/profile/domain/payment_method.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/payment_controller.dart';

/// Profile > Payment Methods: list of saved UPI ids with the ability to add
/// more. Only UPI is supported for now.
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final methodsAsync = ref.watch(paymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(context: context, builder: (_) => const _AddOrEditUpiDialog()),
        icon: const Icon(Icons.add),
        label: const Text('Add UPI'),
      ),
      body: methodsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error is ApiException ? error.message : 'Could not load payment methods.'),
              const SizedBox(height: AppConstants.spacingSm),
              TextButton(onPressed: () => ref.invalidate(paymentMethodsProvider), child: const Text('Retry')),
            ],
          ),
        ),
        data: (methods) => methods.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingXl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 56, color: theme.colorScheme.primary),
                      const SizedBox(height: AppConstants.spacingMd),
                      Text('No payment methods yet', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        'Add a UPI id to get started.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spacingLg,
                  AppConstants.spacingLg,
                  AppConstants.spacingLg,
                  AppConstants.spacingXxl + AppConstants.spacingLg,
                ),
                itemCount: methods.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spacingMd),
                itemBuilder: (context, index) => _PaymentMethodCard(method: methods[index]),
              ),
      ),
    );
  }
}

/// A single payment-method row — its own [ConsumerStatefulWidget] so that
/// setting this method as default shows a loading state on just this row's
/// button (disabled + spinner) while the request is in flight.
class _PaymentMethodCard extends ConsumerStatefulWidget {
  const _PaymentMethodCard({required this.method});

  final PaymentMethod method;

  @override
  ConsumerState<_PaymentMethodCard> createState() => _PaymentMethodCardState();
}

class _PaymentMethodCardState extends ConsumerState<_PaymentMethodCard> {
  bool _settingDefault = false;
  bool _deleting = false;

  Future<void> _setDefault() async {
    setState(() => _settingDefault = true);
    try {
      await ref.read(paymentMethodsProvider.notifier).setDefault(widget.method.id);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _settingDefault = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete payment method?'),
        content: Text('This will remove "${widget.method.upiId}". This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.onErrorContainer,
              backgroundColor: Theme.of(dialogContext).colorScheme.errorContainer,
              backgroundBuilder: flatButtonBackground,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(paymentMethodsProvider.notifier).remove(widget.method.id);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }
    if (mounted) setState(() => _deleting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final method = widget.method;
    final busy = _settingDefault || _deleting;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppAccent.sky.pastel,
          child: Icon(Icons.account_balance_outlined, color: AppAccent.sky.ink),
        ),
        title: Text(method.upiId),
        subtitle: const Text('UPI'),
        onTap: busy ? null : () => showDialog<void>(context: context, builder: (_) => _AddOrEditUpiDialog(existing: method)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (method.isDefault)
              const Padding(
                padding: EdgeInsets.only(right: AppConstants.spacingXs),
                child: Chip(
                  label: Text('Default'),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              )
            else
              TextButton(
                onPressed: busy ? null : _setDefault,
                child: _settingDefault
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Set default'),
              ),
            IconButton(
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
              icon: _deleting
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
              onPressed: busy ? null : _delete,
            ),
          ],
        ),
      ),
    );
  }
}

/// Add-a-new-UPI dialog when [existing] is `null`; edits it in place
/// (`updateUpi`) otherwise.
class _AddOrEditUpiDialog extends ConsumerStatefulWidget {
  const _AddOrEditUpiDialog({this.existing});

  final PaymentMethod? existing;

  bool get isEdit => existing != null;

  @override
  ConsumerState<_AddOrEditUpiDialog> createState() => _AddOrEditUpiDialogState();
}

class _AddOrEditUpiDialogState extends ConsumerState<_AddOrEditUpiDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _upi = TextEditingController(text: widget.existing?.upiId ?? '');
  bool _saving = false;
  String? _error;

  static final _upiPattern = RegExp(r'^[\w.\-]{2,}@[a-zA-Z]{2,}$');

  @override
  void dispose() {
    _upi.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final notifier = ref.read(paymentMethodsProvider.notifier);
      if (widget.isEdit) {
        await notifier.updateUpi(widget.existing!.id, _upi.text.trim());
      } else {
        await notifier.addUpi(_upi.text.trim());
      }
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit UPI' : 'Add UPI'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _upi,
              autofocus: true,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'UPI ID', hintText: 'name@bank'),
              onFieldSubmitted: (_) => _save(),
              validator: (v) => (v == null || !_upiPattern.hasMatch(v.trim())) ? 'Enter a valid UPI id' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppConstants.spacingSm),
              Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
