import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/payment_controller.dart';

/// Profile > Payment Methods: list of saved UPI ids with the ability to add
/// more. Only UPI is supported for now.
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  Future<void> _setDefault(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(paymentMethodsProvider.notifier).setDefault(id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final methodsAsync = ref.watch(paymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(context: context, builder: (_) => const _AddUpiDialog()),
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
                itemBuilder: (context, index) {
                  final method = methods[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.account_balance_outlined, color: theme.colorScheme.onPrimaryContainer),
                      ),
                      title: Text(method.upiId),
                      subtitle: const Text('UPI'),
                      trailing: method.isDefault
                          ? Chip(
                              label: const Text('Default'),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            )
                          : TextButton(
                              onPressed: () => _setDefault(context, ref, method.id),
                              child: const Text('Set default'),
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _AddUpiDialog extends ConsumerStatefulWidget {
  const _AddUpiDialog();

  @override
  ConsumerState<_AddUpiDialog> createState() => _AddUpiDialogState();
}

class _AddUpiDialogState extends ConsumerState<_AddUpiDialog> {
  final _formKey = GlobalKey<FormState>();
  final _upi = TextEditingController();
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
      await ref.read(paymentMethodsProvider.notifier).addUpi(_upi.text.trim());
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
      title: const Text('Add UPI'),
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
              : const Text('Add'),
        ),
      ],
    );
  }
}
