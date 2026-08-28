import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/admin/discounts/domain/admin_promo_code.dart';
import 'package:sunil_medical_store/features/admin/discounts/domain/discount_repository.dart';
import 'package:sunil_medical_store/features/cart/domain/promo_code.dart';

/// [DiscountRepository] backed by the admin promo-codes API
/// (`/v1/admin/promo-codes`). See `docs/API_ENDPOINTS.md` §Admin — Discounts.
class ApiDiscountRepository implements DiscountRepository {
  ApiDiscountRepository(this._dio);

  final Dio _dio;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Future<List<AdminPromoCode>> list() async {
    try {
      final response = await _dio.get<List<dynamic>>('/admin/promo-codes');
      return (response.data ?? const []).cast<Map<String, dynamic>>().map(_fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<AdminPromoCode> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/admin/promo-codes/$id');
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<AdminPromoCode> create(PromoCodeInput input) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/promo-codes',
        data: _toJson(input),
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<AdminPromoCode> update(String id, PromoCodeInput input) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/admin/promo-codes/$id',
        data: _toJson(input),
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/admin/promo-codes/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Map<String, dynamic> _toJson(PromoCodeInput input) => {
    'code': input.code,
    'label': input.label,
    'type': input.type.name,
    'value': input.value,
    'minOrder': input.minOrder,
    'active': input.active,
    'expiresAt': ?(input.expiresAt == null ? null : _dateFormat.format(input.expiresAt!)),
    'maxRedemptions': ?input.maxRedemptions,
    'perUserLimit': ?input.perUserLimit,
  };

  AdminPromoCode _fromJson(Map<String, dynamic> json) => AdminPromoCode(
    // The backend keys promo codes by `code` (no separate id column) — the
    // seed data confirms it: list/detail responses never include `id`, and
    // `code` is what every route (`/admin/promo-codes/{code}`) expects.
    id: (json['id'] as String?) ?? json['code'] as String,
    code: json['code'] as String,
    label: json['label'] as String,
    type: PromoType.values.byName(json['type'] as String),
    value: json['value'] as int,
    minOrder: json['minOrder'] as int? ?? 0,
    active: json['active'] as bool? ?? true,
    expiresAt: json['expiresAt'] == null ? null : DateTime.parse(json['expiresAt'] as String),
    maxRedemptions: json['maxRedemptions'] as int?,
    perUserLimit: json['perUserLimit'] as int?,
    redemptionCount: json['redemptionCount'] as int? ?? 0,
  );
}
