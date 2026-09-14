import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/banners/domain/home_banner.dart';
import 'package:sunil_medical_store/features/admin/banners/presentation/providers/banner_providers.dart';
import 'package:sunil_medical_store/features/admin/banners/presentation/widgets/banner_illustration.dart';

/// Edit one banner slot's title/description/active state. The slot itself
/// (and its illustration) is fixed — only text and active state are
/// admin-editable, see [HomeBanner]'s doc comment.
class EditBannerScreen extends ConsumerStatefulWidget {
  const EditBannerScreen({super.key, required this.banner});

  final HomeBanner? banner;

  @override
  ConsumerState<EditBannerScreen> createState() => _EditBannerScreenState();
}

class _EditBannerScreenState extends ConsumerState<EditBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.banner?.title);
  late final _descriptionController = TextEditingController(text: widget.banner?.description);
  late bool _isActive = widget.banner?.isActive ?? false;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final banner = widget.banner;
    if (banner == null || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(bannerRepositoryProvider)
          .update(
            banner.id,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            isActive: _isActive,
          );
      ref.invalidate(adminBannersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Banner updated')));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final banner = widget.banner;
    if (banner == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Banner')),
        body: const Center(child: Text('Banner not found.')),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(bannerSlotLabel(banner.id))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          children: [
            Center(child: BannerIllustration(bannerId: banner.id, size: 96)),
            const SizedBox(height: AppConstants.spacingLg),
            TextFormField(
              controller: _titleController,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _descriptionController,
              enabled: !_saving,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isActive,
              onChanged: _saving ? null : (v) => setState(() => _isActive = v),
              title: const Text('Active'),
              subtitle: Text(
                'Shown on the customer home screen — cycles with any other active banner',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
