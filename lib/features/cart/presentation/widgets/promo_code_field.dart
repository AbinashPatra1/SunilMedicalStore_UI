import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/cart/domain/promo_repository.dart';
import 'package:sunil_medical_store/features/cart/presentation/providers/cart_providers.dart';

/// Promo-code entry: a text field + Apply, or the applied code with Remove.
class PromoCodeField extends ConsumerStatefulWidget {
  const PromoCodeField({super.key});

  @override
  ConsumerState<PromoCodeField> createState() => _PromoCodeFieldState();
}

class _PromoCodeFieldState extends ConsumerState<PromoCodeField> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final subtotal = ref.read(cartSubtotalProvider);
      final promo = await ref.read(promoRepositoryProvider).validate(code, subtotal: subtotal);
      ref.read(appliedPromoProvider.notifier).apply(promo);
      _controller.clear();
    } on PromoException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final applied = ref.watch(appliedPromoProvider);

    if (applied != null) {
      return Card(
        color: theme.colorScheme.primaryContainer,
        child: ListTile(
          leading: Icon(Icons.local_offer, color: theme.colorScheme.onPrimaryContainer),
          title: Text('${applied.code} applied', style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
          subtitle: Text(applied.label, style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
          trailing: TextButton(
            onPressed: () => ref.read(appliedPromoProvider.notifier).clear(),
            child: const Text('Remove'),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                enabled: !_submitting,
                onSubmitted: (_) => _apply(),
                decoration: const InputDecoration(
                  labelText: 'Promo code',
                  prefixIcon: Icon(Icons.local_offer_outlined),
                ),
              ),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            FilledButton(
              onPressed: _submitting ? null : _apply,
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Apply'),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: AppConstants.spacingXs),
          Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
        ],
      ],
    );
  }
}
