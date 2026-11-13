import 'package:app_core/app/di/injection_container.dart';
import 'package:app_core/app/router/guards/auth_guard.dart';
import 'package:app_core/app/router/not_found_page.dart';
import 'package:app_core/app/router/route_names.dart';
import 'package:app_core/core/config/app_config.dart';
import 'package:app_core/features/example/presentation/bloc/example_bloc.dart';
import 'package:app_core/features/example/presentation/pages/example_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Builds the app's [GoRouter]. Registered in get_it as a lazy singleton.
///
/// Route builders are the only place outside the DI files allowed to call
/// `sl`. Each wraps its page in a `BlocProvider`, so the bloc is scoped to
/// the route and closed automatically when the route is popped.
///
/// Bottom navigation later: wrap the tab routes in a
/// `StatefulShellRoute.indexedStack` (see docs/ARCHITECTURE.md).
GoRouter createAppRouter({
  required AppConfig config,
  required AuthGuard authGuard,
}) {
  return GoRouter(
    initialLocation: RoutePaths.example,
    debugLogDiagnostics: config.enableRouterDiagnostics,
    redirect: authGuard.redirect,
    errorBuilder: (context, state) =>
        NotFoundPage(location: state.uri.toString()),
    routes: [
      GoRoute(
        name: RouteNames.root,
        path: RoutePaths.root,
        redirect: (_, _) => RoutePaths.example,
      ),
      GoRoute(
        name: RouteNames.example,
        path: RoutePaths.example,
        builder: (context, state) => BlocProvider<ExampleBloc>(
          create: (_) => sl<ExampleBloc>()..add(const ExampleEvent.started()),
          child: const ExamplePage(),
        ),
      ),
    ],
  );
}
