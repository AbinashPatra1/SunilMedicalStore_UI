import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/widgets/category_grid.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_category.dart';

/// The full storefront category catalog — reached from the dashboard's
/// "Show All Categories" button. Tapping a category opens the Medicines
/// list filtered to it, same as the dashboard's featured-category tiles.
class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Categories')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: CategoryGrid(
          categories: ProductCategory.values,
          onTap: (category) => context.push(
            '${AppRoutes.medicines}?category=${Uri.encodeComponent(category.label)}',
          ),
        ),
      ),
    );
  }
}
