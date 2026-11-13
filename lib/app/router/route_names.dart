/// Route names. Navigate with `context.goNamed(RouteNames.x)` /
/// `context.pushNamed(RouteNames.x)`, never with raw paths in widgets.
abstract final class RouteNames {
  static const String root = 'root';
  static const String example = 'example';
}

/// Route paths. Only `app_router.dart` should use these.
abstract final class RoutePaths {
  static const String root = '/';
  static const String example = '/example';
}
