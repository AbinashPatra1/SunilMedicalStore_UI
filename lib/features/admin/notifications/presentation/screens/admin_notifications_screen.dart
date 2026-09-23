import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/notifications/notification_payload.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/theme/app_palette.dart';
import 'package:sunil_medical_store/core/widgets/refresh_on_focus.dart';
import 'package:sunil_medical_store/features/admin/notifications/domain/admin_notification.dart';
import 'package:sunil_medical_store/features/admin/notifications/presentation/providers/admin_notification_providers.dart';

/// Admin > More > Notifications: everything the admin has been notified
/// about. Tapping a row marks it read and opens the order, lab-test booking
/// or appointment it refers to.
class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends ConsumerState<AdminNotificationsScreen> {
  bool _markingAll = false;

  Future<void> _open(AdminNotification n) async {
    final route = n.route;
    if (!n.isRead) {
      // Fire and forget — opening the target shouldn't wait on this.
      ref
          .read(adminNotificationRepositoryProvider)
          .markRead(n.id)
          .then((_) => ref.invalidate(adminNotificationsProvider), onError: (_) {});
    }
    if (route != null) await context.push(route);
  }

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    try {
      await ref.read(adminNotificationRepositoryProvider).markAllRead();
      ref.invalidate(adminNotificationsProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(adminNotificationsProvider);
    final hasUnread = async.value?.any((n) => !n.isRead) ?? false;

    return RefreshOnFocus(
      onRefresh: () => refreshIfIdle(ref, adminNotificationsProvider),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            if (hasUnread)
              _markingAll
                  ? const Padding(
                      padding: EdgeInsets.all(AppConstants.spacingMd),
                      child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : TextButton(onPressed: _markAllRead, child: const Text('Mark all read')),
          ],
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error is ApiException ? error.message : 'Could not load notifications.'),
                const SizedBox(height: AppConstants.spacingSm),
                TextButton(
                  onPressed: () => ref.invalidate(adminNotificationsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingXl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none, size: 56, color: theme.colorScheme.primary),
                      const SizedBox(height: AppConstants.spacingMd),
                      Text('No notifications yet', style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        'New orders, bookings and appointments will show up here.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(adminNotificationsProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spacingSm),
                itemBuilder: (context, index) =>
                    _NotificationTile(notification: items[index], onTap: () => _open(items[index])),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AdminNotification notification;
  final VoidCallback onTap;

  static (IconData, AppAccent) _look(NotificationEntityType? type) => switch (type) {
    NotificationEntityType.order => (Icons.receipt_long_outlined, AppAccent.peach),
    NotificationEntityType.appointment => (Icons.calendar_month_outlined, AppAccent.lavender),
    NotificationEntityType.labTest => (Icons.biotech_outlined, AppAccent.sky),
    null => (Icons.notifications_none, AppAccent.mint),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, accent) = _look(notification.type);
    final n = notification;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: accent.pastel,
          child: Icon(icon, color: accent.ink),
        ),
        title: Text(
          n.title,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w800),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (n.body.isNotEmpty) Text(n.body),
            const SizedBox(height: 2),
            Text(
              DateFormat('d MMM yyyy, h:mm a').format(n.createdAt.toLocal()),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        trailing: n.isRead
            ? null
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
              ),
      ),
    );
  }
}
