import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/inventory/domain/inventory_repository.dart';
import 'package:sunil_medical_store/features/admin/inventory/presentation/providers/inventory_providers.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:sunil_medical_store/features/medicines/domain/product.dart';

/// Admin > Inventory > Add / Edit: single form for creating or editing a
/// product. Add mode when [productId] is null; edit mode fetches the
/// existing product to pre-fill.
class AddOrEditProductScreen extends ConsumerWidget {
  const AddOrEditProductScreen({super.key, this.productId});

  final String? productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (productId == null) {
      return const _ProductForm(existing: null);
    }
    final async = ref.watch(adminProductByIdProvider(productId!));
    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit product')),
        body: Center(
          child: Text(error is ApiException ? error.message : 'Could not load product.'),
        ),
      ),
      data: (product) => _ProductForm(existing: product),
    );
  }
}

class _ProductForm extends ConsumerStatefulWidget {
  const _ProductForm({required this.existing});

  final Product? existing;

  bool get isEdit => existing != null;

  @override
  ConsumerState<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<_ProductForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _price;
  late final TextEditingController _mrp;
  late final TextEditingController _stock;
  late final TextEditingController _composition;
  late final TextEditingController _description;
  late final TextEditingController _dosage;
  late final TextEditingController _ingredients;
  late final TextEditingController _imageUrl;

  String? _category;
  bool _requiresPrescription = false;
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _price = TextEditingController(text: p?.price.toString() ?? '');
    _mrp = TextEditingController(text: p?.mrp?.toString() ?? '');
    _stock = TextEditingController(text: p?.stock.toString() ?? '');
    _composition = TextEditingController(text: p?.composition ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _dosage = TextEditingController(text: p?.dosage ?? '');
    _ingredients = TextEditingController(text: p?.ingredients.join(', ') ?? '');
    _imageUrl = TextEditingController(text: p?.imageUrl ?? '');
    _category = p?.category;
    _requiresPrescription = p?.requiresPrescription ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _price.dispose();
    _mrp.dispose();
    _stock.dispose();
    _composition.dispose();
    _description.dispose();
    _dosage.dispose();
    _ingredients.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  String? _requiredInt(String? value, {int min = 0}) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Enter a whole number';
    if (parsed < min) return 'Must be ≥ $min';
    return null;
  }

  String? _optionalInt(String? value, {int min = 0}) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Enter a whole number';
    if (parsed < min) return 'Must be ≥ $min';
    return null;
  }

  ProductInput _buildInput() {
    final ingredientList = _ingredients.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return ProductInput(
      name: _name.text.trim(),
      brand: _brand.text.trim(),
      category: _category!,
      price: int.parse(_price.text.trim()),
      stock: int.parse(_stock.text.trim()),
      requiresPrescription: _requiresPrescription,
      composition: _composition.text.trim().isEmpty ? null : _composition.text.trim(),
      mrp: _mrp.text.trim().isEmpty ? null : int.parse(_mrp.text.trim()),
      description: _description.text.trim(),
      dosage: _dosage.text.trim().isEmpty ? null : _dosage.text.trim(),
      ingredients: ingredientList,
      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      setState(() => _error = 'Choose a category');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final input = _buildInput();
      if (widget.isEdit) {
        await repo.update(widget.existing!.id, input);
      } else {
        await repo.create(input);
      }
      // Refresh the list on the way out.
      ref.invalidate(adminInventoryListProvider);
      if (widget.isEdit) {
        ref.invalidate(adminProductByIdProvider(widget.existing!.id));
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(widget.isEdit ? 'Product updated' : 'Product added'),
          ));
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!widget.isEdit) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          'This will permanently remove "${widget.existing!.name}" from the catalog.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(dialogCtx).colorScheme.onErrorContainer,
              backgroundColor: Theme.of(dialogCtx).colorScheme.errorContainer,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref.read(inventoryRepositoryProvider).delete(widget.existing!.id);
      ref.invalidate(adminInventoryListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Product deleted')));
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(homeCategoriesProvider);
    final busy = _saving || _deleting;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit product' : 'Add product'),
        actions: [
          if (widget.isEdit)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: busy ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          children: [
            TextFormField(
              controller: _name,
              enabled: !busy,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _brand,
              enabled: !busy,
              decoration: const InputDecoration(labelText: 'Brand'),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Could not load categories.'),
              data: (categories) => DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final c in categories)
                    DropdownMenuItem(value: c.label, child: Text(c.label)),
                ],
                onChanged: busy ? null : (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'Choose a category' : null,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    enabled: !busy,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Price (₹)'),
                    validator: (v) => _requiredInt(v, min: 1),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: TextFormField(
                    controller: _mrp,
                    enabled: !busy,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'MRP (₹, optional)'),
                    validator: (v) => _optionalInt(v, min: 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _stock,
              enabled: !busy,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Quantity in stock'),
              validator: (v) => _requiredInt(v),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _composition,
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'Composition',
                hintText: 'e.g. Paracetamol 500mg',
              ),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Requires prescription'),
              value: _requiresPrescription,
              onChanged: busy ? null : (v) => setState(() => _requiresPrescription = v),
            ),
            const Divider(height: AppConstants.spacingXl),
            Text('Optional details', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingSm),
            TextFormField(
              controller: _description,
              enabled: !busy,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _dosage,
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                hintText: 'e.g. 1 tablet twice a day',
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _ingredients,
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'Ingredients',
                hintText: 'Comma-separated',
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _imageUrl,
              enabled: !busy,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Image URL'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppConstants.spacingMd),
              Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: AppConstants.spacingLg),
            FilledButton(
              onPressed: busy ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.isEdit ? 'Save changes' : 'Add product'),
            ),
          ],
        ),
      ),
    );
  }
}
