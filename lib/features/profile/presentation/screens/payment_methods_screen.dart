import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/payment_controller.dart';

/// Profile > Payment Methods: list of saved UPI ids with the ability to add
/// more. Only UPI is supported for now.
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final methods = ref.watch(paymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUpiDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add UPI'),
      ),
      body: methods.isEmpty
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
                            onPressed: () => ref.read(paymentMethodsProvider.notifier).setDefault(method.id),
                            child: const Text('Set default'),
                          ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showAddUpiDialog(BuildContext context, WidgetRef ref) {
    return showDialog<void>(
      context: context,
      builder: (_) => const _AddUpiDialog(),
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

  static final _upiPattern = RegExp(r'^[\w.\-]{2,}@[a-zA-Z]{2,}$');

  @override
  void dispose() {
    _upi.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(paymentMethodsProvider.notifier).addUpi(_upi.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add UPI'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _upi,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'UPI ID', hintText: 'name@bank'),
          onFieldSubmitted: (_) => _save(),
          validator: (v) => (v == null || !_upiPattern.hasMatch(v.trim())) ? 'Enter a valid UPI id' : null,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Add')),
      ],
    );
  }
}
