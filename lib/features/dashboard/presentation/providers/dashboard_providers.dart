import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';

/// A storefront category shown on the dashboard landing page.
class HomeCategory {
  const HomeCategory({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Local icon lookup for category labels — the API's `icon` field is a
/// string name (e.g. `medication_outlined`), and Flutter's `IconData` can't
/// be constructed dynamically from a string at runtime, so the mapping stays
/// client-side, keyed by [label] (per the API doc's own suggestion).
const _categoryIcons = <String, IconData>{
  'Medicines': Icons.medication_outlined,
  'Wellness': Icons.spa_outlined,
  'Personal Care': Icons.face_retouching_natural,
  'Devices': Icons.monitor_heart_outlined,
  'Baby Care': Icons.child_friendly_outlined,
  'Ayurveda': Icons.eco_outlined,
};

/// Home categories, fetched from the (public) catalog API.
final homeCategoriesProvider = FutureProvider<List<HomeCategory>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get<List<dynamic>>('/catalog/categories');
    return (response.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map((json) {
          final label = json['label'] as String;
          return HomeCategory(label: label, icon: _categoryIcons[label] ?? Icons.category_outlined);
        })
        .toList();
  } on DioException catch (e) {
    throw ApiException.fromDioException(e);
  }
});
