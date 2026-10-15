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

/// The dashboard promo banner's card — deliberately **not** a flat
/// `AppCard` like the rest of the app. Decided with the user 2026-10-15
/// (backlog #22's deferred "discuss the promo banner later"): this is the
/// one piece of marketing real estate on the dashboard, so it keeps a
/// vivid brand gradient and a contrasting pill button to stand out from
/// the ordinary flat content around it, while every other surface in the
/// app stays flat per backlog #23.
class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner, required this.onTap});

  final HomeBanner banner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // onPrimary/onSecondary are already the correct contrast color for
    // each theme (white in light mode, dark ink in dark mode — see
    // AppTheme), so reusing them here keeps this card legible in both
    // without a separate dark-mode branch.
    final onGradient = scheme.onPrimary;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.secondary],
        ),
      ),
      child: Stack(
        children: [
          // Soft decorative circles for depth, kept inside the clip.
          Positioned(
            right: -24,
            top: -24,
            child: _softCircle(onGradient, 110),
          ),
          Positioned(
            left: -30,
            bottom: -36,
            child: _softCircle(onGradient, 90),
          ),
          Padding(
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
                        style: theme.textTheme.titleMedium?.copyWith(color: onGradient),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        banner.description,
                        style: theme.textTheme.bodySmall?.copyWith(color: onGradient.withValues(alpha: 0.85)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                      FilledButton(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: onGradient,
                          foregroundColor: scheme.primary,
                        ),
                        child: const Text('Order now'),
                      ),
                    ],
                  ),
                ),
                BannerIllustration(bannerId: banner.id, size: 88),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _softCircle(Color color, double diameter) => Container(
    width: diameter,
    height: diameter,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.08)),
  );
}
