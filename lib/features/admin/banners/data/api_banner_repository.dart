import 'package:dio/dio.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/admin/banners/domain/banner_repository.dart';
import 'package:sunil_medical_store/features/admin/banners/domain/home_banner.dart';

/// [BannerRepository] backed by `/v1/banners` (read, any signed-in user —
/// active only) and `/v1/admin/banners` (read all + write, admin only).
class ApiBannerRepository implements BannerRepository {
  ApiBannerRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<HomeBanner>> activeBanners() => _list('/banners');

  @override
  Future<List<HomeBanner>> adminList() => _list('/admin/banners');

  Future<List<HomeBanner>> _list(String path) async {
    try {
      final response = await _dio.get<List<dynamic>>(path);
      return (response.data ?? const []).cast<Map<String, dynamic>>().map(_fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<HomeBanner> update(
    BannerId id, {
    required String title,
    required String description,
    required bool isActive,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/admin/banners/${id.name}',
        data: {'title': title, 'description': description, 'isActive': isActive},
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  HomeBanner _fromJson(Map<String, dynamic> json) => HomeBanner(
    id: BannerId.values.byName(json['id'] as String),
    title: json['title'] as String,
    description: json['description'] as String,
    isActive: json['isActive'] as bool? ?? false,
  );
}
