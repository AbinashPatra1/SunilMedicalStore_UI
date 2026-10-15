import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Placeholder — replace with the store's real WhatsApp Business number.
const supportWhatsAppNumber = '911234567890';

/// Opens a WhatsApp chat with the store, optionally with [message] pre-filled.
Future<void> openSupportWhatsApp(BuildContext context, {String message = 'Hi, I need help with my order.'}) async {
  final uri = Uri.parse('https://wa.me/$supportWhatsAppNumber?text=${Uri.encodeComponent(message)}');
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
  }
}

/// Published at `docs/privacy-policy.html` in this repo (backlog #29) —
/// resolves once GitHub Pages is enabled for this repo (Settings > Pages >
/// Deploy from a branch > `DEV` / `/docs`), serving this exact path.
const privacyPolicyUrl = 'https://abinashpatra1.github.io/SunilMedicalStore_UI/privacy-policy.html';

/// Opens the privacy policy in the device's browser.
Future<void> openPrivacyPolicy(BuildContext context) async {
  final launched = await launchUrl(Uri.parse(privacyPolicyUrl), mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Could not open the privacy policy.')));
  }
}
