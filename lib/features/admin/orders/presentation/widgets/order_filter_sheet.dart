import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/orders/domain/admin_order_repository.dart';

/// Modal bottom sheet for editing [OrderFilters]. Emits the new value via
/// [onApply] when the user hits Apply; Clear resets to defaults.
class OrderFilterSheet extends StatefulWidget {
  const OrderFilterSheet({super.key, required this.initial, required this.onApply});

  final OrderFilters initial;
  final ValueChanged<OrderFilters> onApply;

  @override
  State<OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends State<OrderFilterSheet> {
  OrderStatus? _status;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _status = widget.initial.status;
    _dateFrom = widget.initial.dateFrom;
    _dateTo = widget.initial.dateTo;
  }

  Future<void> _pickDate(bool from) async {
    final now = DateTime.now();
    final initial = (from ? _dateFrom : _dateTo) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _dateFrom = picked;
        if (_dateTo != null && _dateTo!.isBefore(picked)) _dateTo = picked;
      } else {
        _dateTo = picked;
        if (_dateFrom != null && _dateFrom!.isAfter(picked)) _dateFrom = picked;
      }
    });
  }

  void _apply() {
    // Preserve search from the caller — it's owned by the app bar, not this
    // sheet.
    widget.onApply(OrderFilters(
      search: widget.initial.search,
      status: _status,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    ));
    Navigator.of(context).pop();
  }

  void _clear() {
    widget.onApply(OrderFilters(search: widget.initial.search));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('d MMM yyyy');

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppConstants.spacingLg,
          right: AppConstants.spacingLg,
          top: AppConstants.spacingLg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppConstants.spacingLg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Filters', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  TextButton(onPressed: _clear, child: const Text('Clear')),
                ],
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text('Status', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppConstants.spacingXs),
              Wrap(
                spacing: AppConstants.spacingSm,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _status == null,
                    onSelected: (_) => setState(() => _status = null),
                  ),
                  for (final s in OrderStatus.values)
                    ChoiceChip(
                      label: Text(s.label),
                      selected: _status == s,
                      onSelected: (_) => setState(() => _status = s),
                    ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingLg),
              Text('Date range', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppConstants.spacingXs),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(true),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_dateFrom == null ? 'From' : formatter.format(_dateFrom!)),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(false),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_dateTo == null ? 'To' : formatter.format(_dateTo!)),
                    ),
                  ),
                ],
              ),
              if (_dateFrom != null || _dateTo != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _dateFrom = null;
                      _dateTo = null;
                    }),
                    child: const Text('Clear dates'),
                  ),
                ),
              const SizedBox(height: AppConstants.spacingXl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Apply filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
