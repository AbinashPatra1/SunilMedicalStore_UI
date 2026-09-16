import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/features/admin/inventory/domain/inventory_filters.dart';

/// The Admin Inventory screen's active [AdminInventoryFilters] — set from
/// the top-bar category chips and the dedicated filter screen.
final adminInventoryFiltersProvider =
    NotifierProvider<AdminInventoryFiltersController, AdminInventoryFilters>(
  AdminInventoryFiltersController.new,
);

class AdminInventoryFiltersController extends Notifier<AdminInventoryFilters> {
  @override
  AdminInventoryFilters build() => const AdminInventoryFilters();

  void apply(AdminInventoryFilters filters) => state = filters;
}
