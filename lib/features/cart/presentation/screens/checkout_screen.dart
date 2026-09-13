import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/illustrations/order_success_illustration.dart';
import 'package:sunil_medical_store/core/models/prescription.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/utils/distance.dart';
import 'package:sunil_medical_store/features/admin/delivery/presentation/providers/delivery_settings_providers.dart';
import 'package:sunil_medical_store/features/cart/domain/cart_item.dart';
import 'package:sunil_medical_store/features/cart/domain/order_repository.dart';
import 'package:sunil_medical_store/features/cart/presentation/providers/cart_providers.dart';
import 'package:sunil_medical_store/features/cart/presentation/widgets/payment_option_tile.dart';
import 'package:sunil_medical_store/features/cart/presentation/widgets/price_breakdown.dart';
import 'package:sunil_medical_store/features/prescriptions/presentation/providers/prescription_providers.dart';
import 'package:sunil_medical_store/features/profile/domain/address.dart';
import 'package:sunil_medical_store/features/profile/domain/payment_method.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/address_controller.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/payment_controller.dart';

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

  _PaymentChoice? _payment;

  /// A saved UPI id selected instead of one of the generic [_PaymentChoice]
  /// options — mutually exclusive with [_payment] (see [_select]/[_selectSaved]).
  PaymentMethod? _savedMethod;
  String? _upiError;
  bool _placing = false;

  String? _selectedPrescriptionId;
  bool _uploadingPrescription = false;

  @override
  void dispose() {
    _customUpiController.dispose();
    super.dispose();
  }

  void _changeAddress(List<Address> addresses) {
    final selectedId = ref.read(selectedAddressIdProvider);
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
                trailing: address.id == selectedId
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  ref.read(selectedAddressIdProvider.notifier).select(address.id);
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

  Future<void> _uploadPrescription(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;

    setState(() => _uploadingPrescription = true);
    try {
      final prescription = await ref.read(prescriptionRepositoryProvider).upload(File(picked.path));
      ref.invalidate(prescriptionsProvider);
      if (mounted) setState(() => _selectedPrescriptionId = prescription.id);
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _uploadingPrescription = false);
    }
  }

  void _pickPrescription(List<Prescription> existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLg),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('Attach a prescription', style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: AppConstants.spacingMd),
              for (final p in existing.where((p) => p.status != PrescriptionStatus.rejected))
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(DateFormat('d MMM yyyy').format(p.uploadedOn)),
                  subtitle: Text(p.status.label),
                  trailing: p.id == _selectedPrescriptionId
                      ? Icon(Icons.check_circle, color: Theme.of(sheetContext).colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _selectedPrescriptionId = p.id);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a new photo'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _uploadPrescription(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Upload from gallery'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _uploadPrescription(ImageSource.gallery);
                },
              ),
              const SizedBox(height: AppConstants.spacingMd),
            ],
          ),
        ),
      ),
    );
  }

  void _select(_PaymentChoice choice) {
    setState(() {
      _payment = choice;
      _savedMethod = null;
      _upiError = null;
    });
  }

  void _selectSaved(PaymentMethod method) {
    setState(() {
      _savedMethod = method;
      _payment = null;
      _upiError = null;
    });
  }

  Future<void> _orderNow(Address? address) async {
    if (address == null) {
      _snack('Please add a delivery address in Profile → Addresses.');
      return;
    }
    if (_payment == null && _savedMethod == null) {
      _snack('Please select a payment method.');
      return;
    }
    if (_payment == _PaymentChoice.otherUpi && !_upiPattern.hasMatch(_customUpiController.text.trim())) {
      setState(() => _upiError = 'Enter a valid UPI id (name@bank).');
      return;
    }
    if (ref.read(cartRequiresPrescriptionProvider) && _selectedPrescriptionId == null) {
      _snack('Please attach a prescription for the Rx item(s) in your cart.');
      return;
    }
    final hasPharmacyItems = ref.read(cartProvider).any((item) => item.kind == CartItemKind.medicine);
    // Fail open when we can't verify distance: an address with no captured
    // coordinates (manually entered, or added before this existed) or no
    // configured delivery settings (not deployed yet on the backend) never
    // blocks the order — only a confirmed out-of-radius address does.
    if (hasPharmacyItems && address.latitude != null && address.longitude != null) {
      final settings = ref.read(deliverySettingsProvider).value;
      if (settings != null) {
        final distanceKm = haversineKm(
          address.latitude!,
          address.longitude!,
          settings.storeLatitude,
          settings.storeLongitude,
        );
        if (distanceKm > settings.radiusKm) {
          _snack(
            'This address is outside our ${settings.radiusKm.toStringAsFixed(0)} km pharmacy delivery '
            'area. Lab tests and appointments are unaffected.',
          );
          return;
        }
      }
    }
    await _placeOrder(address);
  }

  Future<void> _placeOrder(Address address) async {
    setState(() => _placing = true);

    final savedMethod = _savedMethod;
    final payment = _payment;
    final wireValue = savedMethod != null ? 'upi' : payment!.wireValue;
    final upiId = savedMethod?.upiId ?? (payment == _PaymentChoice.otherUpi ? _customUpiController.text.trim() : null);
    final paymentLabel = savedMethod != null
        ? 'UPI · ${savedMethod.upiId}'
        : (payment == _PaymentChoice.otherUpi ? 'UPI · ${_customUpiController.text.trim()}' : payment!.label);
    final items = ref.read(cartProvider);
    final promoCode = ref.read(appliedPromoProvider)?.code;

    try {
      final order = await ref.read(orderRepositoryProvider).placeOrder(
        items: [
          for (final item in items)
            OrderRequestItem(
              kind: item.kind,
              catalogId: item.catalogId,
              quantity: item.quantity,
              scheduledDate: item.scheduledDate,
              timeSlot: item.timeSlot,
            ),
        ],
        addressId: address.id,
        promoCode: promoCode,
        paymentMethod: wireValue,
        upiId: upiId,
        prescriptionId: _selectedPrescriptionId,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const OrderSuccessIllustration(size: 88),
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
    // Prefetched here (unused directly in the UI) so it's already resolved
    // by the time _orderNow's radius check reads it via ref.read.
    ref.watch(deliverySettingsProvider);
    final addresses = ref.watch(addressesProvider).value ?? const <Address>[];
    final address = ref.watch(selectedAddressProvider);
    final savedMethods = ref.watch(paymentMethodsProvider).value ?? const <PaymentMethod>[];
    final total = ref.watch(cartTotalProvider);
    final needsPrescription = ref.watch(cartRequiresPrescriptionProvider);
    final prescriptions = ref.watch(prescriptionsProvider).value ?? const <Prescription>[];
    Prescription? selectedPrescription;
    for (final p in prescriptions) {
      if (p.id == _selectedPrescriptionId) {
        selectedPrescription = p;
        break;
      }
    }

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
                if (needsPrescription) ...[
                  const SizedBox(height: AppConstants.spacingLg),
                  Text('Prescription required', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppConstants.spacingSm),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        selectedPrescription == null ? Icons.warning_amber_outlined : Icons.description_outlined,
                        color: selectedPrescription == null ? theme.colorScheme.error : null,
                      ),
                      title: Text(
                        selectedPrescription == null
                            ? 'No prescription attached'
                            : DateFormat('d MMM yyyy').format(selectedPrescription.uploadedOn),
                      ),
                      subtitle: Text(
                        selectedPrescription == null
                            ? 'Your cart has a prescription-only item'
                            : selectedPrescription.status.label,
                      ),
                      trailing: (_placing || _uploadingPrescription)
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: () => _pickPrescription(prescriptions),
                              child: Text(selectedPrescription == null ? 'Attach' : 'Change'),
                            ),
                    ),
                  ),
                ],
                if (savedMethods.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.spacingLg),
                  Text('Saved UPI', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppConstants.spacingSm),
                  for (final method in savedMethods)
                    PaymentOptionTile(
                      icon: Icons.account_balance_outlined,
                      title: method.upiId,
                      subtitle: method.isDefault ? 'Default' : null,
                      selected: _savedMethod?.id == method.id,
                      onTap: _placing ? () {} : () => _selectSaved(method),
                    ),
                ],
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
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4))),
            ),
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
