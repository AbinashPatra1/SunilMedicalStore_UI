import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/routes/app_router.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';

/// Shows a dismissible banner over whatever screen is currently visible —
/// the in-app equivalent of a system push notification, for
/// [FirebaseMessaging.onMessage] (the OS never shows its own tray
/// notification while the app is foregrounded, so without this the
/// customer/admin would miss the event entirely). Auto-dismisses after a
/// few seconds; tapping it (if [onTap] is given) also dismisses it.
void showInAppNotificationBanner({
  required String title,
  required String body,
  VoidCallback? onTap,
}) {
  final overlay = rootNavigatorKey.currentState?.overlay;
  if (overlay == null) return;

  late final OverlayEntry entry;
  var removed = false;
  void remove() {
    if (removed) return;
    removed = true;
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (context) => _NotificationBanner(
      title: title,
      body: body,
      onTap: onTap == null
          ? null
          : () {
              remove();
              onTap();
            },
      onDismiss: remove,
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 5), remove);
}

class _NotificationBanner extends StatelessWidget {
  const _NotificationBanner({
    required this.title,
    required this.body,
    required this.onTap,
    required this.onDismiss,
  });

  final String title;
  final String body;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingSm),
          child: Material(
            elevation: 3,
            shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            color: theme.colorScheme.surfaceContainerHigh,
            surfaceTintColor: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.notifications_outlined,
                        size: 18,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: theme.textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            body,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: onDismiss,
                      borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                      child: Icon(Icons.close, size: 18, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
