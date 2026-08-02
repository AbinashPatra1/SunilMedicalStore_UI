import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/users/domain/admin_user.dart';
import 'package:sunil_medical_store/features/admin/users/presentation/providers/admin_users_providers.dart';

/// Modal bottom sheet: search + browse all users, tap to pick.
/// Pops the chosen [AdminUser] as its result.
class PickUserSheet extends ConsumerStatefulWidget {
  const PickUserSheet({super.key});

  @override
  ConsumerState<PickUserSheet> createState() => _PickUserSheetState();
}

class _PickUserSheetState extends ConsumerState<PickUserSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(adminUsersProvider(_query));
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.8;

    return SizedBox(
      height: sheetHeight,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppConstants.spacingLg,
          right: AppConstants.spacingLg,
          top: AppConstants.spacingSm,
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text('Pick a user', style: theme.textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search by name or phone',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Center(child: Text('Could not load users.')),
                data: (users) {
                  if (users.isEmpty) {
                    return const Center(child: Text('No matching users.'));
                  }
                  return ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final AdminUser user = users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            user.initials,
                            style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                          ),
                        ),
                        title: Text(user.fullName),
                        subtitle: Text(user.displayPhone),
                        onTap: () => Navigator.of(context).pop(user),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
