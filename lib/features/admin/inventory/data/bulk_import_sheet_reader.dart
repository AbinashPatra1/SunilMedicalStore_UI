import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:sunil_medical_store/features/admin/inventory/domain/bulk_import_parser.dart';

/// Decodes an `.xlsx` file's first sheet into a plain string grid (first
/// row = headers) — the only place in this feature that touches the
/// `excel` package, so [parseBulkImportRows] (domain layer) stays a pure
/// function over strings with no file-format dependency.
List<List<String?>> readSheetAsGrid(Uint8List bytes) {
  final workbook = Excel.decodeBytes(bytes);
  if (workbook.tables.isEmpty) return const [];
  final sheet = workbook.tables[workbook.tables.keys.first]!;
  return [
    for (final row in sheet.rows) [for (final cell in row) cell?.value?.toString().trim()],
  ];
}

/// Builds a downloadable `.xlsx` template: the exact header row
/// [readSheetAsGrid]/[parseBulkImportRows] expect, plus one filled-in
/// example row, so an admin can see the right shape without guessing.
Uint8List buildSampleImportWorkbookBytes() {
  final workbook = Excel.createExcel();
  final sheetName = workbook.getDefaultSheet() ?? workbook.tables.keys.first;
  final sheet = workbook[sheetName];

  sheet.appendRow([
    for (final c in kBulkImportRequiredColumns) TextCellValue(c),
    for (final c in kBulkImportOptionalColumns) TextCellValue(c),
  ]);
  sheet.appendRow([
    TextCellValue('Paracetamol 500mg Tablets'),
    TextCellValue('Micro Labs'),
    TextCellValue('Pain Relief'),
    TextCellValue('Tablet Drug'),
    IntCellValue(30),
    IntCellValue(100),
    TextCellValue('Paracetamol 500mg'),
    TextCellValue('No'),
    IntCellValue(35),
    TextCellValue('Relieves mild to moderate pain and reduces fever'),
    TextCellValue('1 tablet every 6 hours, as needed (max 4/day)'),
    TextCellValue('Paracetamol, Starch, Povidone'),
    TextCellValue(''),
    TextCellValue('10 tablets'),
  ]);

  final bytes = workbook.save();
  if (bytes == null) {
    throw StateError('Failed to generate the sample workbook.');
  }
  return Uint8List.fromList(bytes);
}
