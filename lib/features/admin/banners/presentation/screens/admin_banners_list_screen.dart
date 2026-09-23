import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/banners/domain/home_banner.dart';
import 'package:sunil_medical_store/features/admin/banners/presentation/providers/banner_providers.dart';
import 'package:sunil_medical_store/features/admin/banners/presentation/widgets/banner_illustration.dart';
import 'package:sunil_medical_store/core/widgets/refresh_on_focus.dart';

/// Admin > More > Home Banners: the fixed 12-slot catalog of dashboard promo
/// banners. Each row can be quick-toggled active/inactive inline, or tapped
/// to edit its title/description.
class AdminBannersListScreen extends ConsumerWidget {
  const AdminBannersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bannersAsync = ref.watch(adminBannersProvider);

    return RefreshOnFocus(
      onRefresh: () { refreshIfIdle(ref, adminBannersProvider); },
      child: Scaffold(
      appBar: AppBar(title: const Text('Home Banners')),
      body: bannersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error is ApiException ? error.message : 'Could not load banners.'),
              const SizedBox(height: AppConstants.spacingSm),
              TextButton(onPressed: () => ref.invalidate(adminBannersProvider), child: const Text('Retry')),
            ],
          ),
        ),
        data: (banners) => ListView(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          children: [
            Text(
              'When more than one banner is active, the customer home screen cycles through them.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            for (final banner in banners)
              Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
                child: _BannerTile(banner: banner),
              ),
          ],
        ),
      ),
    ),
    );
  }
}

class _BannerTile extends ConsumerStatefulWidget {
  const _BannerTile({required this.banner});

  final HomeBanner banner;

  @override
  ConsumerState<_BannerTile> createState() => _BannerTileState();
}

class _BannerTileState extends ConsumerState<_BannerTile> {
  bool _togglingActive = false;

  Future<void> _toggleActive(bool value) async {
    setState(() => _togglingActive = true);
    try {
      await ref
          .read(bannerRepositoryProvider)
          .update(
            widget.banner.id,
            title: widget.banner.title,
            description: widget.banner.description,
            isActive: value,
          );
      ref.invalidate(adminBannersProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _togglingActive = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final banner = widget.banner;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        onTap: () => context.push('${AppRoutes.adminBannerEdit}/${banner.id.name}', extra: banner),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                child: ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: BannerIllustration(bannerId: banner.id, size: 44),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bannerSlotLabel(banner.id),
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Text(banner.title, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              _togglingActive
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Switch(value: banner.isActive, onChanged: _toggleActive),
            ],
          ),
        ),
      ),
    );
  }
}
