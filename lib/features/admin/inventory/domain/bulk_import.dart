import 'package:sunil_medical_store/features/admin/inventory/domain/inventory_repository.dart';

/// One row parsed from an admin-uploaded bulk-import spreadsheet.
///
/// [input] is non-null only when the row passed every client-side
/// validation check (mirrors the Add/Edit form's own rules) — [isValid]
/// is the single source of truth for whether this row gets sent to the
/// backend. [name]/[brand] are kept even on an invalid row (best-effort,
/// may be null) purely so the preview list can still identify which row a
/// validation error belongs to.
class BulkImportRow {
  const BulkImportRow({
    required this.rowNumber,
    required this.name,
    required this.brand,
    required this.input,
    this.errors = const [],
  });

  /// 1-indexed position in the sheet, matching what the admin sees when
  /// they open it in a spreadsheet app (header row is row 1).
  final int rowNumber;
  final String? name;
  final String? brand;
  final ProductInput? input;
  final List<String> errors;

  bool get isValid => errors.isEmpty && input != null;
}

/// Result of parsing an uploaded sheet: either a sheet-level problem (a
/// required column is missing entirely — nothing else can be checked until
/// that's fixed) or a row-by-row breakdown.
class BulkImportParseResult {
  const BulkImportParseResult.rows(this.rows) : headerError = null;
  const BulkImportParseResult.headerError(String this.headerError) : rows = const [];

  final String? headerError;
  final List<BulkImportRow> rows;

  bool get hasHeaderError => headerError != null;
  List<BulkImportRow> get validRows => rows.where((r) => r.isValid).toList();
  List<BulkImportRow> get invalidRows => rows.where((r) => !r.isValid).toList();
}

/// Per-row outcome of an actual `POST /admin/products/bulk-import` call —
/// distinct from [BulkImportRow], which is the client's own pre-flight
/// check. A row can pass client validation and still `failed` here (e.g. a
/// server-side rule the client doesn't know about).
enum BulkImportOutcome { created, updated, failed }

class BulkImportRowOutcome {
  const BulkImportRowOutcome({
    required this.row,
    required this.name,
    required this.brand,
    required this.outcome,
    this.id,
    this.reason,
  });

  final int row;
  final String name;
  final String brand;
  final BulkImportOutcome outcome;
  final String? id;
  final String? reason;
}

class BulkImportSummary {
  const BulkImportSummary({
    required this.results,
    required this.createdCount,
    required this.updatedCount,
    required this.failedCount,
  });

  final List<BulkImportRowOutcome> results;
  final int createdCount;
  final int updatedCount;
  final int failedCount;
}
