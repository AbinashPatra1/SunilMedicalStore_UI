import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/banners/domain/home_banner.dart';
import 'package:sunil_medical_store/features/admin/banners/presentation/providers/banner_providers.dart';
import 'package:sunil_medical_store/features/admin/banners/presentation/widgets/banner_illustration.dart';

/// Dashboard promo banner — cycles through every admin-active [HomeBanner]
/// (Admin > More > Home Banners) with a [PageView] + auto-advance timer and
/// dot indicators. Falls back to a single static banner (matching the
/// original default "General Discount 1" copy) whenever the backend
/// endpoint errors or hasn't been deployed yet, so the dashboard never shows
/// an empty gap purely because this feature isn't live server-side yet —
/// same fail-open philosophy used throughout this app.
class HomeBannerCarousel extends ConsumerStatefulWidget {
  const HomeBannerCarousel({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  ConsumerState<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends ConsumerState<HomeBannerCarousel> {
  final _pageController = PageController();
  Timer? _timer;
  int _page = 0;
  int? _timerForCount;

  static const _fallback = HomeBanner(
    id: BannerId.generalDiscount1,
    title: 'Up to 25% off on medicines',
    description: 'Order your monthly refills and save more.',
    isActive: true,
  );

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _ensureAutoAdvance(int count) {
    if (_timerForCount == count) return;
    _timerForCount = count;
    _timer?.cancel();
    if (count <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      _page = (_page + 1) % count;
      _pageController.animateToPage(_page, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(activeBannersProvider);

    return bannersAsync.when(
      loading: () => _BannerCard(banner: _fallback, onTap: widget.onTap),
      error: (_, _) => _BannerCard(banner: _fallback, onTap: widget.onTap),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();
        if (banners.length == 1) return _BannerCard(banner: banners.first, onTap: widget.onTap);

        _ensureAutoAdvance(banners.length);
        return Column(
          children: [
            SizedBox(
              height: 206,
              child: PageView.builder(
                controller: _pageController,
                itemCount: banners.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _BannerCard(banner: banners[i], onTap: widget.onTap),
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < banners.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner, required this.onTap});

  final HomeBanner banner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    banner.title,
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text(
                    banner.description,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  FilledButton(onPressed: onTap, child: const Text('Order now')),
                ],
              ),
            ),
            BannerIllustration(bannerId: banner.id, size: 88),
          ],
        ),
      ),
    );
  }
}
