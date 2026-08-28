import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/discounts/domain/admin_promo_code.dart';
import 'package:sunil_medical_store/features/admin/discounts/presentation/providers/discount_providers.dart';
import 'package:sunil_medical_store/features/cart/domain/promo_code.dart';

/// Admin > Discounts > Add / Edit: single form for creating or editing a
/// promo code. Add mode when [promoCodeId] is null; edit mode fetches the
/// existing code to pre-fill.
class AddOrEditPromoCodeScreen extends ConsumerWidget {
  const AddOrEditPromoCodeScreen({super.key, this.promoCodeId});

  final String? promoCodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (promoCodeId == null) {
      return const _PromoCodeForm(existing: null);
    }
    final async = ref.watch(adminPromoCodeByIdProvider(promoCodeId!));
    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit code')),
        body: Center(
          child: Text(error is ApiException ? error.message : 'Could not load promo code.'),
        ),
      ),
      data: (promoCode) => _PromoCodeForm(existing: promoCode),
    );
  }
}

class _PromoCodeForm extends ConsumerStatefulWidget {
  const _PromoCodeForm({required this.existing});

  final AdminPromoCode? existing;

  bool get isEdit => existing != null;

  @override
  ConsumerState<_PromoCodeForm> createState() => _PromoCodeFormState();
}

class _PromoCodeFormState extends ConsumerState<_PromoCodeForm> {
  final _formKey = GlobalKey<FormState>();
  static final _dateFormat = DateFormat('d MMM yyyy');

  late final TextEditingController _code;
  late final TextEditingController _label;
  late final TextEditingController _value;
  late final TextEditingController _minOrder;
  late final TextEditingController _maxRedemptions;
  late final TextEditingController _perUserLimit;

  late PromoType _type;
  late bool _active;
  DateTime? _expiresAt;
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _code = TextEditingController(text: p?.code ?? '');
    _label = TextEditingController(text: p?.label ?? '');
    _value = TextEditingController(text: p?.value.toString() ?? '');
    _minOrder = TextEditingController(text: p != null && p.minOrder > 0 ? p.minOrder.toString() : '');
    _maxRedemptions = TextEditingController(text: p?.maxRedemptions?.toString() ?? '');
    _perUserLimit = TextEditingController(text: p?.perUserLimit?.toString() ?? '');
    _type = p?.type ?? PromoType.percentage;
    _active = p?.active ?? true;
    _expiresAt = p?.expiresAt;
  }

  @override
  void dispose() {
    _code.dispose();
    _label.dispose();
    _value.dispose();
    _minOrder.dispose();
    _maxRedemptions.dispose();
    _perUserLimit.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  String? _requiredInt(String? value, {int min = 0}) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Enter a whole number';
    if (parsed < min) return 'Must be ≥ $min';
    return null;
  }

  String? _optionalInt(String? value, {int min = 1}) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Enter a whole number';
    if (parsed < min) return 'Must be ≥ $min';
    return null;
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  PromoCodeInput _buildInput() => PromoCodeInput(
    code: _code.text.trim().toUpperCase(),
    label: _label.text.trim(),
    type: _type,
    value: int.parse(_value.text.trim()),
    minOrder: _minOrder.text.trim().isEmpty ? 0 : int.parse(_minOrder.text.trim()),
    active: _active,
    expiresAt: _expiresAt,
    maxRedemptions: _maxRedemptions.text.trim().isEmpty ? null : int.parse(_maxRedemptions.text.trim()),
    perUserLimit: _perUserLimit.text.trim().isEmpty ? null : int.parse(_perUserLimit.text.trim()),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(discountRepositoryProvider);
      final input = _buildInput();
      if (widget.isEdit) {
        await repo.update(widget.existing!.id, input);
      } else {
        await repo.create(input);
      }
      ref.invalidate(adminPromoCodesProvider);
      if (widget.isEdit) {
        ref.invalidate(adminPromoCodeByIdProvider(widget.existing!.id));
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(widget.isEdit ? 'Promo code updated' : 'Promo code added'),
          ));
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
        title: const Text('Delete promo code?'),
        content: Text('This will permanently remove "${widget.existing!.code}".'),
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
    setState(() => _deleting = true);
    try {
      await ref.read(discountRepositoryProvider).delete(widget.existing!.id);
      ref.invalidate(adminPromoCodesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Promo code deleted')));
        context.pop();
      }
    } on ApiException catch (e) {
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
    final theme = Theme.of(context);
    final busy = _saving || _deleting;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit code' : 'Add code'),
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
              controller: _code,
              enabled: !busy,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Code', hintText: 'e.g. SAVE10'),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _label,
              enabled: !busy,
              decoration: const InputDecoration(labelText: 'Label', hintText: 'e.g. 10% off your order'),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            DropdownButtonFormField<PromoType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: PromoType.percentage, child: Text('Percentage off')),
                DropdownMenuItem(value: PromoType.flat, child: Text('Flat amount off')),
              ],
              onChanged: busy ? null : (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _value,
                    enabled: !busy,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: _type == PromoType.percentage ? 'Percent off' : 'Amount off (₹)',
                    ),
                    validator: (v) => _requiredInt(v, min: 1),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: TextFormField(
                    controller: _minOrder,
                    enabled: !busy,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Min order (₹, optional)'),
                    validator: _optionalInt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              subtitle: const Text('Off pauses the code without deleting it'),
              value: _active,
              onChanged: busy ? null : (v) => setState(() => _active = v),
            ),
            const Divider(height: AppConstants.spacingXl),
            Text('Optional limits', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingSm),
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_busy_outlined),
                title: Text(_expiresAt == null ? 'No expiry date' : _dateFormat.format(_expiresAt!)),
                trailing: Wrap(
                  spacing: AppConstants.spacingXs,
                  children: [
                    TextButton(
                      onPressed: busy ? null : _pickExpiry,
                      child: Text(_expiresAt == null ? 'Set' : 'Change'),
                    ),
                    if (_expiresAt != null)
                      IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.clear),
                        onPressed: busy ? null : () => setState(() => _expiresAt = null),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxRedemptions,
                    enabled: !busy,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Max total uses',
                      hintText: 'Unlimited',
                    ),
                    validator: _optionalInt,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: TextFormField(
                    controller: _perUserLimit,
                    enabled: !busy,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Max uses/user',
                      hintText: 'Unlimited',
                    ),
                    validator: _optionalInt,
                  ),
                ),
              ],
            ),
            if (widget.isEdit) ...[
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                '${widget.existing!.redemptionCount} redemption(s) so far',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppConstants.spacingMd),
              Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: AppConstants.spacingLg),
            FilledButton(
              onPressed: busy ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.isEdit ? 'Save changes' : 'Add code'),
            ),
          ],
        ),
      ),
    );
  }
}
