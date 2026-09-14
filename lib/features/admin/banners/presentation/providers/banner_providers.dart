import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/banners/data/api_banner_repository.dart';
import 'package:sunil_medical_store/features/admin/banners/domain/banner_repository.dart';
import 'package:sunil_medical_store/features/admin/banners/domain/home_banner.dart';

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  return ApiBannerRepository(ref.watch(dioProvider));
});

/// All 12 banner slots — Admin > More > Home Banners list.
final adminBannersProvider = FutureProvider<List<HomeBanner>>((ref) {
  return ref.watch(bannerRepositoryProvider).adminList();
});

/// Only the active banners, in catalog order — the dashboard carousel reads
/// this directly (see `features/dashboard/presentation/widgets/
/// home_banner_carousel.dart`), same cross-feature-read pattern as
/// `deliverySettingsProvider`.
final activeBannersProvider = FutureProvider<List<HomeBanner>>((ref) {
  return ref.watch(bannerRepositoryProvider).activeBanners();
});
