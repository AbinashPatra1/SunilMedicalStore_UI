import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/inventory/data/bulk_import_sheet_reader.dart';
import 'package:sunil_medical_store/features/admin/inventory/domain/bulk_import.dart';
import 'package:sunil_medical_store/features/admin/inventory/domain/bulk_import_parser.dart';
import 'package:sunil_medical_store/features/admin/inventory/presentation/providers/inventory_providers.dart';

/// Admin > Inventory > Import: pick an `.xlsx` file, preview which rows are
/// valid/invalid (client-side, mirrors the Add/Edit form's own validation),
/// then send only the valid rows to the backend (`POST
/// /admin/products/bulk-import`, backlog #13 — see
/// `docs/API_ENDPOINTS.md` §Admin — Inventory #78). **Built ahead of the
/// backend** — that endpoint isn't deployed yet, so Import currently fails
/// cleanly with the standard error surface; everything up to and including
/// the preview works today.
class BulkImportScreen extends ConsumerStatefulWidget {
  const BulkImportScreen({super.key});

  @override
  ConsumerState<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends ConsumerState<BulkImportScreen> {
  BulkImportParseResult? _parseResult;
  BulkImportSummary? _summary;
  bool _busy = false;
  String? _error;

  Future<void> _pickAndParse() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['xlsx']);
      if (file == null) return; // user cancelled
      final bytes = await file.readAsBytes();
      final grid = readSheetAsGrid(bytes);
      final result = parseBulkImportRows(grid);
      setState(() {
        if (result.hasHeaderError) {
          _error = result.headerError;
        } else {
          _parseResult = result;
        }
      });
    } catch (_) {
      setState(() => _error = 'Could not read that file. Make sure it is a valid .xlsx spreadsheet.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final valid = _parseResult!.validRows.map((r) => r.input!).toList();
    if (valid.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final summary = await ref.read(inventoryRepositoryProvider).bulkImport(valid);
      ref.invalidate(adminInventoryListProvider);
      if (mounted) setState(() => _summary = summary);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startOver() {
    setState(() {
      _parseResult = null;
      _summary = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk import')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        children: [
          if (_summary != null)
            _ResultView(summary: _summary!)
          else if (_parseResult != null)
            _PreviewView(result: _parseResult!)
          else ...[
            const _IntroView(),
            const SizedBox(height: AppConstants.spacingMd),
            const _SampleDownloadButton(),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppConstants.spacingMd),
            _ErrorCard(message: _error!),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: _bottomAction(),
        ),
      ),
    );
  }

  Widget _bottomAction() {
    if (_summary != null) {
      return FilledButton(
        onPressed: () => context.pop(),
        child: const Text('Done'),
      );
    }
    if (_parseResult != null) {
      final validCount = _parseResult!.validRows.length;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: (_busy || validCount == 0) ? null : _import,
            child: _busy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(validCount == 0 ? 'No valid rows to import' : 'Import $validCount product${validCount == 1 ? '' : 's'}'),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          TextButton(
            onPressed: _busy ? null : _startOver,
            child: const Text('Choose a different file'),
          ),
        ],
      );
    }
    return FilledButton.icon(
      onPressed: _busy ? null : _pickAndParse,
      icon: _busy
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.upload_file_outlined),
      label: const Text('Choose file (.xlsx)'),
    );
  }
}

class _IntroView extends StatelessWidget {
  const _IntroView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.table_chart_outlined, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: AppConstants.spacingMd),
            Text('Import products from a spreadsheet', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              'Upload an .xlsx file with one product per row. A product already '
              'in the catalog with the same Name + Brand is updated; otherwise '
              'a new one is created. You\'ll see a preview before anything is '
              'imported.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Text('Required columns', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              kBulkImportRequiredColumns.join(', '),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text('Optional columns', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              kBulkImportOptionalColumns.join(', '),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lets the admin save a ready-made `.xlsx` template (correct headers + one
/// filled-in example row) via the system "Save As" picker, so they don't
/// have to guess the column names/order from the intro card's text alone.
class _SampleDownloadButton extends StatefulWidget {
  const _SampleDownloadButton();

  @override
  State<_SampleDownloadButton> createState() => _SampleDownloadButtonState();
}

class _SampleDownloadButtonState extends State<_SampleDownloadButton> {
  bool _saving = false;

  Future<void> _download() async {
    setState(() => _saving = true);
    try {
      final bytes = buildSampleImportWorkbookBytes();
      final uri = await FilePicker.saveFile(
        fileName: 'product_import_template.xlsx',
        bytes: bytes,
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (uri != null && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Sample file saved')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Could not save the sample file.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _saving ? null : _download,
      icon: _saving
          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.download_outlined),
      label: const Text('Download sample file'),
    );
  }
}

class _PreviewView extends StatelessWidget {
  const _PreviewView({required this.result});

  final BulkImportParseResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valid = result.validRows;
    final invalid = result.invalidRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Row(
              children: [
                Icon(
                  invalid.isEmpty ? Icons.check_circle_outline : Icons.info_outline,
                  color: invalid.isEmpty ? theme.colorScheme.primary : theme.colorScheme.error,
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Text(
                    '${valid.length} row${valid.length == 1 ? '' : 's'} ready to import'
                    '${invalid.isEmpty ? '' : ', ${invalid.length} with issues'}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (invalid.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacingLg),
          Text('Rows with issues (won\'t be imported)', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppConstants.spacingSm),
          for (final row in invalid) _IssueRowTile(row: row),
        ],
      ],
    );
  }
}

class _IssueRowTile extends StatelessWidget {
  const _IssueRowTile({required this.row});

  final BulkImportRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = [
      if (row.name != null) row.name,
      if (row.brand != null) row.brand,
    ].join(' — ');

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Row ${row.rowNumber}${label.isEmpty ? '' : ' — $label'}',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: AppConstants.spacingXs),
            for (final e in row.errors)
              Text(
                '• $e',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.summary});

  final BulkImportSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = summary.results.where((r) => r.outcome == BulkImportOutcome.failed).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, size: 40, color: theme.colorScheme.primary),
                const SizedBox(height: AppConstants.spacingMd),
                Text('Import complete', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppConstants.spacingSm),
                Text('${summary.createdCount} created, ${summary.updatedCount} updated'
                    '${summary.failedCount == 0 ? '' : ', ${summary.failedCount} failed'}'),
              ],
            ),
          ),
        ),
        if (failed.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacingLg),
          Text('Rows the server rejected', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppConstants.spacingSm),
          for (final r in failed)
            Card(
              margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
              child: ListTile(
                title: Text('Row ${r.row} — ${r.name} — ${r.brand}'),
                subtitle: Text(
                  r.reason ?? 'Unknown error',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Text(message, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
      ),
    );
  }
}
