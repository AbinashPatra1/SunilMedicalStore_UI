import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/illustrations/category_illustration.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_category.dart';

/// Non-scrolling grid of storefront categories.
///
/// Designed to sit inside a scrolling parent, so it shrink-wraps and disables
/// its own scrolling.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.categories,
    required this.onTap,
  });

  final List<ProductCategory> categories;
  final ValueChanged<ProductCategory> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppConstants.spacingMd,
        crossAxisSpacing: AppConstants.spacingMd,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryTile(category: category, onTap: () => onTap(category));
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final ProductCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium!;
    // Reserve space for the max 2 lines regardless of how many the label
    // actually wraps to, so every tile has the same content height and the
    // illustration lines up across a row even when a neighbor's label is
    // shorter (a variable-height label here would otherwise shift the
    // whole centered column up/down tile by tile).
    final labelBoxHeight = (labelStyle.fontSize ?? 12) * (labelStyle.height ?? 1.2) * 2;

    return InkWell(
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CategoryIllustration(category: category, size: 56),
          const SizedBox(height: AppConstants.spacingSm),
          SizedBox(
            height: labelBoxHeight,
            child: Text(
              category.label,
              style: labelStyle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
