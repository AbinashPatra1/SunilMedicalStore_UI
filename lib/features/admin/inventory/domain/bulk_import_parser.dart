import 'package:sunil_medical_store/features/admin/inventory/domain/bulk_import.dart';
import 'package:sunil_medical_store/features/admin/inventory/domain/inventory_repository.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_category.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_type.dart';

/// Column headers this importer understands, matched case-insensitively
/// against the sheet's first row, in any order. Mirrors exactly what the
/// Add/Edit product form requires/accepts — see `docs/API_ENDPOINTS.md`
/// §Admin — Inventory (#78) for the same table.
const kBulkImportRequiredColumns = [
  'Name',
  'Brand',
  'Category',
  'Product Type',
  'Price',
  'Quantity',
  'Composition',
  'Rx Required',
];

const kBulkImportOptionalColumns = [
  'MRP',
  'Description',
  'Dosage',
  'Ingredients',
  'Image URL',
  'Pack Size',
];

/// Validates and converts a raw spreadsheet grid (first row = headers) into
/// [BulkImportRow]s, applying the same rules as the Add/Edit product form
/// (mandatory fields, category/type must match the fixed catalogs, numeric
/// fields parse) plus an intra-file duplicate Name+Brand check. Pure
/// function over plain strings — knows nothing about `excel`/`file_picker`,
/// so it's trivially testable and reusable if the source format ever
/// changes.
BulkImportParseResult parseBulkImportRows(List<List<String?>> grid) {
  if (grid.isEmpty) {
    return const BulkImportParseResult.headerError('The file is empty.');
  }

  final header = grid.first.map((h) => (h ?? '').trim().toLowerCase()).toList();
  final columnIndex = <String, int>{};
  for (var i = 0; i < header.length; i++) {
    if (header[i].isNotEmpty) columnIndex[header[i]] = i;
  }

  final missing = [
    for (final c in kBulkImportRequiredColumns)
      if (!columnIndex.containsKey(c.toLowerCase())) c,
  ];
  if (missing.isNotEmpty) {
    return BulkImportParseResult.headerError(
      'Missing required column${missing.length > 1 ? 's' : ''}: ${missing.join(', ')}',
    );
  }

  String? cell(List<String?> row, String column) {
    final idx = columnIndex[column.toLowerCase()];
    if (idx == null || idx >= row.length) return null;
    final v = row[idx]?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  final rows = <BulkImportRow>[];
  final seenKeys = <String>{};

  for (var r = 1; r < grid.length; r++) {
    final row = grid[r];
    if (row.every((v) => (v ?? '').trim().isEmpty)) continue; // skip blank rows

    final rowNumber = r + 1; // header is row 1, so first data row is 2
    final errors = <String>[];

    final name = cell(row, 'Name');
    if (name == null) errors.add('Name is required');
    final brand = cell(row, 'Brand');
    if (brand == null) errors.add('Brand is required');

    ProductCategory? category;
    final categoryText = cell(row, 'Category');
    if (categoryText == null) {
      errors.add('Category is required');
    } else {
      category = ProductCategory.fromLabel(categoryText);
      if (category == null) errors.add('Unknown category "$categoryText"');
    }

    ProductType? type;
    final typeText = cell(row, 'Product Type');
    if (typeText == null) {
      errors.add('Product Type is required');
    } else {
      type = _matchProductType(typeText);
      if (type == null) errors.add('Unknown product type "$typeText"');
    }

    int? price;
    final priceText = cell(row, 'Price');
    if (priceText == null) {
      errors.add('Price is required');
    } else {
      price = int.tryParse(priceText);
      if (price == null || price < 1) errors.add('Price must be a whole number ≥ 1');
    }

    int? stock;
    final stockText = cell(row, 'Quantity');
    if (stockText == null) {
      errors.add('Quantity is required');
    } else {
      stock = int.tryParse(stockText);
      if (stock == null || stock < 0) errors.add('Quantity must be a whole number ≥ 0');
    }

    final composition = cell(row, 'Composition');
    if (composition == null) errors.add('Composition is required');

    bool? requiresPrescription;
    final rxText = cell(row, 'Rx Required');
    if (rxText == null) {
      errors.add('Rx Required is required');
    } else {
      requiresPrescription = _parseBool(rxText);
      if (requiresPrescription == null) errors.add('Rx Required must be Yes/No');
    }

    int? mrp;
    final mrpText = cell(row, 'MRP');
    if (mrpText != null) {
      mrp = int.tryParse(mrpText);
      if (mrp == null || mrp < 1) errors.add('MRP must be a whole number ≥ 1');
    }

    if (name != null && brand != null) {
      final key = '${name.toLowerCase()}|${brand.toLowerCase()}';
      if (!seenKeys.add(key)) {
        errors.add('Duplicate Name + Brand elsewhere in this file');
      }
    }

    ProductInput? input;
    if (errors.isEmpty) {
      input = ProductInput(
        name: name!,
        brand: brand!,
        category: category!.label,
        price: price!,
        stock: stock!,
        requiresPrescription: requiresPrescription!,
        composition: composition,
        mrp: mrp,
        description: cell(row, 'Description') ?? '',
        dosage: cell(row, 'Dosage'),
        ingredients: (cell(row, 'Ingredients') ?? '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        imageUrl: cell(row, 'Image URL'),
        packSize: cell(row, 'Pack Size'),
        type: type,
      );
    }

    rows.add(BulkImportRow(rowNumber: rowNumber, name: name, brand: brand, input: input, errors: errors));
  }

  return BulkImportParseResult.rows(rows);
}

ProductType? _matchProductType(String text) {
  final normalized = text.trim().toLowerCase();
  for (final t in ProductType.values) {
    if (t.label.toLowerCase() == normalized || t.name.toLowerCase() == normalized) return t;
  }
  return null;
}

bool? _parseBool(String text) {
  switch (text.trim().toLowerCase()) {
    case 'yes':
    case 'true':
    case 'y':
    case '1':
      return true;
    case 'no':
    case 'false':
    case 'n':
    case '0':
      return false;
    default:
      return null;
  }
}
