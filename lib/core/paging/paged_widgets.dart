import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/paging/paged.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';

/// A list that loads its next page as the user nears the bottom (customer
/// screens). Shows a small spinner (or a retry) as its last row while more
/// pages remain. [header] rows come first and aren't part of the paging.
class InfiniteListView<T> extends StatefulWidget {
  const InfiniteListView({
    super.key,
    required this.state,
    required this.onLoadMore,
    required this.itemBuilder,
    this.header = const [],
    this.padding = const EdgeInsets.all(AppConstants.spacingLg),
    this.separatorHeight = AppConstants.spacingMd,
  });

  final PagedState<T> state;
  final VoidCallback onLoadMore;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final List<Widget> header;
  final EdgeInsetsGeometry padding;
  final double separatorHeight;

  @override
  State<InfiniteListView<T>> createState() => _InfiniteListViewState<T>();
}

class _InfiniteListViewState<T> extends State<InfiniteListView<T>> {
  final _controller = ScrollController();

  static const _threshold = 400.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    final s = widget.state;
    if (!s.hasMore || s.busy || s.loadError != null) return;
    if (!_controller.hasClients) return;
    if (_controller.position.extentAfter < _threshold) widget.onLoadMore();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    // A short first page may not fill the screen, so no scroll event would
    // ever ask for the next one — check after every layout as well.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeLoadMore();
    });

    final headerCount = widget.header.length;
    final showFooter = s.hasMore || s.loadError != null;
    final count = headerCount + s.items.length + (showFooter ? 1 : 0);

    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        _maybeLoadMore();
        return false;
      },
      child: ListView.separated(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: widget.padding,
        itemCount: count,
        separatorBuilder: (_, _) => SizedBox(height: widget.separatorHeight),
        itemBuilder: (context, index) {
          if (index < headerCount) return widget.header[index];
          final i = index - headerCount;
          if (i < s.items.length) return widget.itemBuilder(context, s.items[i]);
          return _Footer(failed: s.loadError != null, onRetry: widget.onLoadMore);
        },
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.failed, required this.onRetry});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
      child: Center(
        child: failed
            ? TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Couldn\'t load more — tap to retry'),
              )
            : const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}

/// Numbered pager for the admin lists: ‹ 1 2 3 4 5 ›. Falls back to
/// ‹ Page N › when the backend doesn't report a total.
class PageNumberBar extends StatelessWidget {
  const PageNumberBar({super.key, required this.state, required this.onSelect});

  final PagedState<Object?> state;
  final ValueChanged<int> onSelect;

  static const _window = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = state.pageCount;
    final page = state.page;
    if ((count != null && count <= 1) || (count == null && page == 1 && !state.hasMore)) {
      return const SizedBox.shrink();
    }

    final canPrev = page > 1 && !state.busy;
    final canNext = (count != null ? page < count : state.hasMore) && !state.busy;

    Widget arrow(IconData icon, bool enabled, int target, String tooltip) => IconButton(
      tooltip: tooltip,
      onPressed: enabled ? () => onSelect(target) : null,
      icon: Icon(icon),
    );

    final numbers = <Widget>[];
    if (count == null) {
      numbers.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
        child: Text('Page $page', style: theme.textTheme.titleSmall),
      ));
    } else {
      final start = (page - _window ~/ 2).clamp(1, (count - _window + 1).clamp(1, count));
      final end = (start + _window - 1).clamp(1, count);
      for (var p = start; p <= end; p++) {
        final selected = p == page;
        numbers.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: SizedBox(
              width: 40,
              height: 40,
              child: selected
                  ? FilledButton(
                      onPressed: null,
                      style: FilledButton.styleFrom(padding: EdgeInsets.zero, disabledBackgroundColor: theme.colorScheme.primary, disabledForegroundColor: theme.colorScheme.onPrimary),
                      child: Text('$p'),
                    )
                  : TextButton(
                      onPressed: state.busy ? null : () => onSelect(p),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text('$p'),
                    ),
            ),
          ),
        );
      }
    }

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              arrow(Icons.chevron_left, canPrev, page - 1, 'Previous page'),
              ...numbers,
              arrow(Icons.chevron_right, canNext, page + 1, 'Next page'),
              if (state.busy)
                const Padding(
                  padding: EdgeInsets.only(left: AppConstants.spacingSm),
                  child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
