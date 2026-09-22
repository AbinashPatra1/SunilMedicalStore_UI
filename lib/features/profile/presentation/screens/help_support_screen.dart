import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_palette.dart';
import 'package:sunil_medical_store/core/widgets/app_card.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/utils/support_contact.dart';

/// Profile > Help & Support: a WhatsApp Business chat shortcut plus common
/// FAQs. FAQ copy is placeholder pending real content from the store.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
      question: 'How do I track my order?',
      answer:
          'Go to Profile > Orders and tap the order to see its current status. '
          'You\'ll also get a notification whenever the status changes.',
    ),
    (
      question: 'How do I cancel an order or appointment?',
      answer:
          'Orders can be cancelled from Profile > Orders while they\'re still '
          'being processed. Appointments can be cancelled from Profile > '
          'Appointments up until the scheduled time.',
    ),
    (
      question: 'Do I need a prescription for all medicines?',
      answer:
          'Only medicines marked "Rx required" need a valid prescription. '
          'You can upload one from the Prescriptions section or during checkout.',
    ),
    (
      question: 'What are your delivery charges?',
      answer:
          'Delivery is free above a minimum order value; below that, a small '
          'distance-based delivery fee applies and is shown at checkout '
          'before you place the order.',
    ),
    (
      question: 'How do I add or change my delivery address?',
      answer:
          'Go to Profile > Addresses to add a new address, edit an existing '
          'one, or set a different one as default.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppAccent.mint.pastel,
                child: Icon(Icons.chat_outlined, color: AppAccent.mint.ink),
              ),
              title: const Text('Chat with us on WhatsApp'),
              subtitle: const Text('Get help from our support team'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openSupportWhatsApp(context),
            ),
          ),
          const SizedBox(height: AppConstants.spacingXl),
          Text(
            'Frequently asked questions',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < _faqs.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    title: Text(
                      _faqs[i].question,
                      style: theme.textTheme.bodyMedium,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(
                      AppConstants.spacingMd,
                      0,
                      AppConstants.spacingMd,
                      AppConstants.spacingMd,
                    ),
                    expandedAlignment: Alignment.centerLeft,
                    children: [
                      Text(
                        _faqs[i].answer,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
