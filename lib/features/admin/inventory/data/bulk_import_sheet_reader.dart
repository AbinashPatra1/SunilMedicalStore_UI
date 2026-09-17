import 'dart:typed_data';

import 'package:excel/excel.dart';

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
