import 'package:flutter/widgets.dart';

/// Route observers for `RefreshOnFocus`. A [NavigatorObserver] can only watch
/// one navigator, so the root navigator and each bottom-nav tab's navigator
/// get their own (see `app_router.dart`); `RefreshOnFocus` picks the one
/// attached to the navigator its screen lives in.
final appRouteObservers = List.generate(11, (_) => RouteObserver<ModalRoute<void>>());
