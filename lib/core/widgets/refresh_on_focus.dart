import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable, ProviderOrFamily;
import 'package:sunil_medical_store/core/routes/app_route_observer.dart';

/// Runs [onRefresh] whenever the screen it wraps is (re)shown by
/// navigation: when it is pushed (so a cached list is refetched instead of
/// showing stale data) and when the route above it is popped (so a list picks
/// up what was just created/cancelled/returned on a detail screen).
///
/// Refreshing is done by invalidating the screen's providers, which keeps
/// the previous data on screen while the new fetch runs — no spinner flash.
class RefreshOnFocus extends StatefulWidget {
  const RefreshOnFocus({super.key, required this.onRefresh, required this.child});

  final VoidCallback onRefresh;
  final Widget child;

  @override
  State<RefreshOnFocus> createState() => _RefreshOnFocusState();
}

class _RefreshOnFocusState extends State<RefreshOnFocus> with RouteAware {
  ModalRoute<void>? _route;
  RouteObserver<ModalRoute<void>>? _observer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _route) {
      _observer?.unsubscribe(this);
      _route = route;
      final navigator = Navigator.of(context);
      _observer = null;
      for (final o in appRouteObservers) {
        if (o.navigator == navigator) _observer = o;
      }
      _observer?.subscribe(this, route);
    }
  }

  // Deferred to after the frame: `subscribe` reports the initial push while
  // the widget tree is still building, and providers must not be invalidated
  // mid-build.
  void _refreshSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onRefresh();
    });
  }

  @override
  void didPush() => _refreshSoon();

  @override
  void didPopNext() => _refreshSoon();

  @override
  void dispose() {
    _observer?.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Invalidates [provider] unless it is already mid-fetch — so opening a
/// screen for the first time (fetch already in flight) doesn't request the
/// same data twice, while a screen with cached data gets a fresh fetch.
void refreshIfIdle(WidgetRef ref, ProviderListenable<AsyncValue<Object?>> provider) {
  if (ref.read(provider).isLoading) return;
  ref.invalidate(provider as ProviderOrFamily);
}
