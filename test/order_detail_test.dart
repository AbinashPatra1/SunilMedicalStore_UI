import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/features/admin/delivery/domain/delivery_settings.dart';
import 'package:sunil_medical_store/features/cart/presentation/providers/reorder.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/order_detail_sections.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

DeliverySettings settings({bool returns = true, int days = 7}) => DeliverySettings(
  storeLatitude: 0,
  storeLongitude: 0,
  radiusKm: 10,
  returnsEnabled: returns,
  returnWindowDays: days,
);

void main() {
  group('OrderAddress.tryParse', () {
    test('accepts a string or an object, ignores junk', () {
      expect(OrderAddress.tryParse('12 MG Road, Pune')!.formatted, '12 MG Road, Pune');
      expect(
        OrderAddress.tryParse({'line1': 'Kondapur', 'area': 'Gachibowli', 'city': 'Hyderabad', 'state': 'Telangana', 'pincode': '500084'})!
            .formatted,
        'Kondapur, Gachibowli, Hyderabad, Telangana 500084',
      );
      expect(OrderAddress.tryParse(null), isNull);
      expect(OrderAddress.tryParse(42), isNull);
    });
  });

  group('ReorderResult.message', () {
    test('all added', () {
      expect(
        const ReorderResult(added: 2, unavailable: [], skippedLabTests: 0).message,
        'All items in this order are added to cart.',
      );
    });
    test('some out of stock', () {
      final m = const ReorderResult(added: 1, unavailable: ['A', 'B'], skippedLabTests: 0).message;
      expect(m, contains('A, B'));
      expect(m, contains('The rest of the items are added to cart.'));
    });
    test('none added, lab tests skipped', () {
      final m = const ReorderResult(added: 0, unavailable: ['A'], skippedLabTests: 1).message;
      expect(m, contains('Nothing was added'));
      expect(m, contains('Lab tests were skipped'));
    });
  });

  group('sections', () {
    testWidgets('summary card shows delivered date and all three progress labels', (tester) async {
      await tester.pumpWidget(
        wrap(OrderSummaryCard(status: OrderStatus.delivered, placedOn: DateTime(2026, 9, 1), deliveredOn: DateTime(2026, 9, 5))),
      );
      expect(find.text('Delivered on 5 Sep 2026'), findsOneWidget);
      expect(find.text('Created'), findsOneWidget);
      expect(find.text('Processed'), findsOneWidget);
      expect(find.text('Delivered'), findsWidgets);
    });

    testWidgets('bill shows every cost line, free delivery and the payment method', (tester) async {
      await tester.pumpWidget(
        wrap(
          const OrderItemsBillCard(
            items: [OrderItem(name: 'Dettol', quantity: 2, price: 145)],
            subtotal: 290,
            discount: 29,
            delivery: 0,
            platformFee: 12,
            total: 273,
            paymentMethod: 'razorpay',
          ),
        ),
      );
      expect(find.text('₹290'), findsWidgets);
      expect(find.text('−₹29'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('₹12'), findsOneWidget);
      expect(find.text('₹273'), findsOneWidget);
      expect(find.text('Paid online (Razorpay)'), findsOneWidget);
    });

    testWidgets('policy section: return text follows the admin setting', (tester) async {
      const delivered = OrderPolicyInput(status: OrderStatus.delivered, deliveredOn: null, orderNumber: 'PHSMS-1');
      await tester.pumpWidget(wrap(OrderPolicySection(order: delivered, settings: settings(returns: true, days: 5))));
      expect(find.textContaining('within 5 days of delivery'), findsOneWidget);

      await tester.pumpWidget(wrap(OrderPolicySection(order: delivered, settings: settings(returns: false))));
      expect(find.textContaining('return'), findsNothing);
    });

    testWidgets('policy section: cancel note for a created order, help only when asked', (tester) async {
      const created = OrderPolicyInput(status: OrderStatus.created, deliveredOn: null, orderNumber: 'PHSMS-1');
      await tester.pumpWidget(wrap(OrderPolicySection(order: created, settings: null, showHelp: true)));
      expect(find.textContaining('can cancel this order until it is processed'), findsOneWidget);
      expect(find.text('Contact us'), findsOneWidget);

      await tester.pumpWidget(wrap(OrderPolicySection(order: created, settings: null)));
      expect(find.text('Contact us'), findsNothing);
    });

    testWidgets('info card lists address, order id and date', (tester) async {
      await tester.pumpWidget(
        wrap(OrderInfoCard(address: 'Home, Bhubaneswar', orderNumber: 'PHSMS-0926-0011', placedOn: DateTime(2026, 9, 21, 19, 7))),
      );
      expect(find.text('Home, Bhubaneswar'), findsOneWidget);
      expect(find.text('PHSMS-0926-0011'), findsOneWidget);
      expect(find.text('21 Sep 2026, 7:07 PM'), findsOneWidget);
    });
  });
}
