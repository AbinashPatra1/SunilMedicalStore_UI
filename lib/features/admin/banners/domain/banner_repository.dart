import 'package:sunil_medical_store/features/admin/banners/domain/home_banner.dart';

/// Backs Admin > More > Home Banners (admin CRUD over a fixed 12-slot
/// catalog) and the dashboard's cycling promo banner (customer read of only
/// the active ones), implemented by the data layer.
abstract interface class BannerRepository {
  /// All 12 slots, active or not — for the admin list.
  Future<List<HomeBanner>> adminList();

  /// Only active banners, in catalog order — for the dashboard carousel.
  Future<List<HomeBanner>> activeBanners();

  Future<HomeBanner> update(
    BannerId id, {
    required String title,
    required String description,
    required bool isActive,
  });
}
