import 'dart:async';

import 'package:app_core/app/router/route_names.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Placeholder auth guard, used as the GoRouter `redirect`.
// TODO(auth): inject an auth repository/cubit, return `/login` when signed
// out, and pass its stream as the router's `refreshListenable` so redirects
// re-run when auth state changes.
class AuthGuard {
  new({bool Function()? isAuthenticated})
    : _isAuthenticated = isAuthenticated ?? (() => true);

  final bool Function() _isAuthenticated;

  /// Routes reachable without signing in.
  static const Set<String> publicPaths = {RoutePaths.root};

  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    final isPublic = publicPaths.contains(state.matchedLocation);
    if (!_isAuthenticated() && !isPublic) {
      // TODO(auth): return the login route path here.
      return null;
    }
    return null;
  }
}
