import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/cart/domain/order_repository.dart';
import 'package:sunil_medical_store/features/cart/presentation/providers/cart_providers.dart';
import 'package:sunil_medical_store/features/cart/presentation/widgets/payment_option_tile.dart';
import 'package:sunil_medical_store/features/cart/presentation/widgets/price_breakdown.dart';
import 'package:sunil_medical_store/features/profile/domain/address.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/address_controller.dart';

enum _PaymentChoice {
  googlePay('Google Pay', 'googlePay', Icons.account_balance_wallet_outlined),
  phonePe('PhonePe', 'phonePe', Icons.phone_android),
  bhim('BHIM', 'bhim', Icons.account_balance),
  otherUpi('Other UPI', 'upi', Icons.alternate_email),
  cod('Cash on Delivery', 'cod', Icons.payments_outlined);

  const _PaymentChoice(this.label, this.wireValue, this.icon);
  final String label;

  /// The value the orders API expects for `paymentMethod`.
  final String wireValue;
  final IconData icon;
}

/// Checkout: choose a delivery address and payment method, then place the order.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _upiPattern = RegExp(r'^[\w.\-]{2,}@[a-zA-Z]{2,}$');
  final _customUpiController = TextEditingController();

  String? _selectedAddressId;
  _PaymentChoice? _payment;
  String? _upiError;
  bool _placing = false;

  @override
  void dispose() {
    _customUpiController.dispose();
    super.dispose();
  }

  Address? _defaultAddress(List<Address> list) {
    for (final a in list) {
      if (a.isDefault) return a;
    }
    return list.isEmpty ? null : list.first;
  }

  Address? _selectedAddress(List<Address> list) {
    if (_selectedAddressId != null) {
      for (final a in list) {
        if (a.id == _selectedAddressId) return a;
      }
    }
    return _defaultAddress(list);
  }

  void _changeAddress(List<Address> addresses) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          children: [
            Text('Select delivery address', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingMd),
            for (final address in addresses)
              ListTile(
                leading: Icon(_addressIcon(address.type)),
                title: Text(address.type.label),
                subtitle: Text(address.formatted),
                trailing: address.id == _selectedAddressId
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedAddressId = address.id);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  IconData _addressIcon(AddressType type) => switch (type) {
    AddressType.home => Icons.home_outlined,
    AddressType.work => Icons.work_outline,
    AddressType.other => Icons.location_on_outlined,
  };

  void _select(_PaymentChoice choice) {
    setState(() {
      _payment = choice;
      _upiError = null;
    });
  }

  Future<void> _orderNow(Address? address) async {
    if (address == null) {
      _snack('Please add a delivery address in Profile → Addresses.');
      return;
    }
    if (_payment == null) {
      _snack('Please select a payment method.');
      return;
    }
    if (_payment == _PaymentChoice.otherUpi && !_upiPattern.hasMatch(_customUpiController.text.trim())) {
      setState(() => _upiError = 'Enter a valid UPI id (name@bank).');
      return;
    }
    await _placeOrder(address);
  }

  Future<void> _placeOrder(Address address) async {
    setState(() => _placing = true);

    final payment = _payment!;
    final items = ref.read(cartProvider);
    final promoCode = ref.read(appliedPromoProvider)?.code;

    try {
      final order = await ref.read(orderRepositoryProvider).placeOrder(
        items: [
          for (final item in items)
            OrderRequestItem(kind: item.kind, catalogId: item.catalogId, quantity: item.quantity),
        ],
        addressId: address.id,
        promoCode: promoCode,
        paymentMethod: payment.wireValue,
        upiId: payment == _PaymentChoice.otherUpi ? _customUpiController.text.trim() : null,
      );

      if (!mounted) return;
      final paymentLabel = payment == _PaymentChoice.otherUpi
          ? 'UPI · ${_customUpiController.text.trim()}'
          : payment.label;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(Icons.check_circle, color: Theme.of(dialogContext).colorScheme.primary, size: 48),
          title: const Text('Order placed!'),
          content: Text(
            'Order ${order.orderNumber} for ₹${order.total} will be delivered to your '
            '${address.type.label} address.\n\nPayment: $paymentLabel',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );

      ref.read(cartProvider.notifier).clear();
      ref.read(appliedPromoProvider.notifier).clear();
      if (mounted) context.go(AppRoutes.pharmacy);
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addresses = ref.watch(addressesProvider).value ?? const <Address>[];
    final address = _selectedAddress(addresses);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              children: [
                Text('Delivery address', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppConstants.spacingSm),
                Card(
                  child: ListTile(
                    leading: Icon(address == null ? Icons.location_off_outlined : _addressIcon(address.type)),
                    title: Text(address?.type.label ?? 'No address'),
                    subtitle: Text(address?.formatted ?? 'Add one from Profile → Addresses'),
                    trailing: addresses.isEmpty
                        ? null
                        : TextButton(
                            onPressed: _placing ? null : () => _changeAddress(addresses),
                            child: const Text('Change'),
                          ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingLg),
                Text('Pay using UPI', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppConstants.spacingSm),
                for (final choice in [_PaymentChoice.googlePay, _PaymentChoice.phonePe, _PaymentChoice.bhim, _PaymentChoice.otherUpi]) ...[
                  PaymentOptionTile(
                    icon: choice.icon,
                    title: choice.label,
                    selected: _payment == choice,
                    onTap: _placing ? () {} : () => _select(choice),
                  ),
                  if (choice == _PaymentChoice.otherUpi && _payment == _PaymentChoice.otherUpi)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
                      child: TextField(
                        controller: _customUpiController,
                        autofocus: true,
                        enabled: !_placing,
                        decoration: InputDecoration(
                          labelText: 'Your UPI ID',
                          hintText: 'name@bank',
                          errorText: _upiError,
                          prefixIcon: const Icon(Icons.alternate_email),
                        ),
                        onChanged: (_) {
                          if (_upiError != null) setState(() => _upiError = null);
                        },
                      ),
                    ),
                ],
                const SizedBox(height: AppConstants.spacingMd),
                Text('Other', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppConstants.spacingSm),
                PaymentOptionTile(
                  icon: _PaymentChoice.cod.icon,
                  title: _PaymentChoice.cod.label,
                  subtitle: 'Pay with cash when your order arrives',
                  selected: _payment == _PaymentChoice.cod,
                  onTap: _placing ? () {} : () => _select(_PaymentChoice.cod),
                ),
                const SizedBox(height: AppConstants.spacingLg),
                Text('Order summary', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppConstants.spacingSm),
                const PriceBreakdown(),
              ],
            ),
          ),
          Material(
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _placing ? null : () => _orderNow(address),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
                      child: _placing
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text('Order Now · ₹$total'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
