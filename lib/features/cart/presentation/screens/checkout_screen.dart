import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_palette.dart';
import 'package:sunil_medical_store/core/widgets/app_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:sunil_medical_store/core/illustrations/order_success_illustration.dart';
import 'package:sunil_medical_store/core/models/prescription.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_colors.dart';
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
import 'package:sunil_medical_store/features/profile/presentation/providers/address_controller.dart';

enum _PaymentChoice {
  online('Pay online', 'razorpay', Icons.payment_outlined),
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
  late final Razorpay _razorpay;

  _PaymentChoice? _payment;
  bool _placing = false;

  /// Set right before opening Razorpay checkout so the success/error
  /// callbacks (which carry no context of their own) know which address to
  /// place the order against once payment completes.
  Address? _checkoutAddress;

  String? _selectedPrescriptionId;
  bool _uploadingPrescription = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onRazorpayExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
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
            Text(
              'Select delivery address',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            for (final address in addresses)
              ListTile(
                leading: Icon(_addressIcon(address.type)),
                title: Text(address.type.label),
                subtitle: Text(address.formatted),
                trailing: address.id == selectedId
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  ref
                      .read(selectedAddressIdProvider.notifier)
                      .select(address.id);
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
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingPrescription = true);
    try {
      final prescription = await ref
          .read(prescriptionRepositoryProvider)
          .upload(File(picked.path));
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLg,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                'Attach a prescription',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: AppConstants.spacingMd),
              for (final p in existing.where(
                (p) => p.status != PrescriptionStatus.rejected,
              ))
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(DateFormat('d MMM yyyy').format(p.uploadedOn)),
                  subtitle: Text(p.status.label),
                  trailing: p.id == _selectedPrescriptionId
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(sheetContext).colorScheme.primary,
                        )
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
    setState(() => _payment = choice);
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
    if (ref.read(cartRequiresPrescriptionProvider) &&
        _selectedPrescriptionId == null) {
      _snack('Please attach a prescription for the Rx item(s) in your cart.');
      return;
    }
    final hasPharmacyItems = ref
        .read(cartProvider)
        .any((item) => item.kind == CartItemKind.medicine);
    // Fail open when we can't verify distance: an address with no captured
    // coordinates (manually entered, or added before this existed) or no
    // configured delivery settings (not deployed yet on the backend) never
    // blocks the order — only a confirmed out-of-radius address does.
    if (hasPharmacyItems &&
        address.latitude != null &&
        address.longitude != null) {
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
    if (_payment == _PaymentChoice.online) {
      await _payOnline(address);
    } else {
      await _placeOrder(address);
    }
  }

  List<OrderRequestItem> _cartAsRequestItems() => [
    for (final item in ref.read(cartProvider))
      OrderRequestItem(
        kind: item.kind,
        catalogId: item.catalogId,
        quantity: item.quantity,
        scheduledDate: item.scheduledDate,
        timeSlot: item.timeSlot,
      ),
  ];

  /// Pay-online flow: get a Razorpay order for the authoritatively-priced
  /// cart, then open Razorpay's own checkout UI. [_onRazorpaySuccess] picks
  /// up from there and calls [_placeOrder] once payment succeeds.
  Future<void> _payOnline(Address address) async {
    setState(() => _placing = true);
    try {
      final details = await ref
          .read(orderRepositoryProvider)
          .createRazorpayOrder(
            items: _cartAsRequestItems(),
            addressId: address.id,
            promoCode: ref.read(appliedPromoProvider)?.code,
          );
      if (!mounted) return;
      _checkoutAddress = address;
      _razorpay.open({
        'key': details.keyId,
        'order_id': details.razorpayOrderId,
        'amount': details.amount,
        'currency': details.currency,
        'name': 'Sunil Medical Store',
        'description': 'Order payment',
        'theme': {'color': AppColors.primaryHex},
      });
    } on ApiException catch (e) {
      if (mounted) {
        _snack(e.message);
        setState(() => _placing = false);
      }
    }
  }

  void _onRazorpaySuccess(PaymentSuccessResponse response) {
    final address = _checkoutAddress;
    if (address == null) return;
    _placeOrder(
      address,
      razorpayOrderId: response.orderId,
      razorpayPaymentId: response.paymentId,
      razorpaySignature: response.signature,
    );
  }

  void _onRazorpayError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _placing = false);
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      _snack('Payment cancelled.');
      return;
    }
    // The native bridge sometimes hands back the literal string "undefined"
    // (or "null") instead of a real message/null — never show that verbatim.
    final message = response.message;
    final hasRealMessage =
        message != null &&
        message.isNotEmpty &&
        message != 'undefined' &&
        message != 'null';
    _snack(hasRealMessage ? message : 'Payment failed. Please try again.');
  }

  void _onRazorpayExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _placing = false);
    _snack(
      'Selected wallet: ${response.walletName}. Please complete the payment there and try again.',
    );
  }

  Future<void> _placeOrder(
    Address address, {
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? razorpaySignature,
  }) async {
    setState(() => _placing = true);

    final payment = _payment!;

    try {
      final order = await ref
          .read(orderRepositoryProvider)
          .placeOrder(
            items: _cartAsRequestItems(),
            addressId: address.id,
            promoCode: ref.read(appliedPromoProvider)?.code,
            paymentMethod: payment.wireValue,
            prescriptionId: _selectedPrescriptionId,
            razorpayOrderId: razorpayOrderId,
            razorpayPaymentId: razorpayPaymentId,
            razorpaySignature: razorpaySignature,
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
            '${address.type.label} address.\n\nPayment: ${payment.label}',
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
    final total = ref.watch(cartTotalProvider);
    final needsPrescription = ref.watch(cartRequiresPrescriptionProvider);
    final prescriptions =
        ref.watch(prescriptionsProvider).value ?? const <Prescription>[];
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
                AppCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(
                      address == null
                          ? Icons.location_off_outlined
                          : _addressIcon(address.type),
                    ),
                    title: Text(address?.type.label ?? 'No address'),
                    subtitle: Text(
                      address?.formatted ?? 'Add one from Profile → Addresses',
                    ),
                    trailing: addresses.isEmpty
                        ? null
                        : TextButton(
                            onPressed: _placing
                                ? null
                                : () => _changeAddress(addresses),
                            child: const Text('Change'),
                          ),
                  ),
                ),
                if (needsPrescription) ...[
                  const SizedBox(height: AppConstants.spacingLg),
                  Text(
                    'Prescription required',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: Icon(
                        selectedPrescription == null
                            ? Icons.warning_amber_outlined
                            : Icons.description_outlined,
                        color: selectedPrescription == null
                            ? theme.colorScheme.error
                            : null,
                      ),
                      title: Text(
                        selectedPrescription == null
                            ? 'No prescription attached'
                            : DateFormat(
                                'd MMM yyyy',
                              ).format(selectedPrescription.uploadedOn),
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
                              child: Text(
                                selectedPrescription == null
                                    ? 'Attach'
                                    : 'Change',
                              ),
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: AppConstants.spacingLg),
                Text('Payment method', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppConstants.spacingSm),
                PaymentOptionTile(
                  icon: _PaymentChoice.online.icon,
                  title: _PaymentChoice.online.label,
                  subtitle: 'UPI, cards, netbanking and wallets via Razorpay',
                  selected: _payment == _PaymentChoice.online,
                  onTap: _placing
                      ? () {}
                      : () => _select(_PaymentChoice.online),
                ),
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
              color: AppPalette.barColor(theme),
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: AppPalette.cartActionButtonStyle(context),
                    onPressed: _placing ? null : () => _orderNow(address),
                    child: _placing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Order Now · ₹$total'),
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
