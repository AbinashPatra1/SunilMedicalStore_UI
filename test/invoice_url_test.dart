import 'package:flutter_test/flutter_test.dart';
import 'package:sunil_medical_store/core/utils/invoice_url.dart';

void main() {
  test('flags the backend\'s known placeholder domain', () {
    expect(isPlaceholderInvoiceUrl('https://api.sunilmedicalstore.com/invoices/123.pdf'), isTrue);
  });

  test('flags a missing or unparsable host', () {
    expect(isPlaceholderInvoiceUrl(''), isTrue);
    expect(isPlaceholderInvoiceUrl('not a url'), isTrue);
  });

  test('accepts a real, different host', () {
    expect(isPlaceholderInvoiceUrl('https://storage.example-cdn.net/invoices/123.pdf'), isFalse);
  });
}
