// Backlog #32: the backend's invoiceUrl currently points at this placeholder
// domain (no real PDF generation yet) — see docs/API_ENDPOINTS.md. It never
// resolves, so opening it in a browser just shows a broken-page error that
// reads as the app being broken. Detecting it here lets the client show a
// clear, honest message instead of launching a dead link.
const _placeholderInvoiceHost = 'api.sunilmedicalstore.com';

/// Whether [url] is the backend's known placeholder invoice domain (not yet
/// generating real PDFs) rather than a real, openable invoice.
bool isPlaceholderInvoiceUrl(String url) {
  final host = Uri.tryParse(url)?.host;
  return host == null || host.isEmpty || host == _placeholderInvoiceHost;
}
