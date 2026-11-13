/// App-wide constants.
///
/// [appName] is the ONLY place in Dart code that holds the product name.
/// See docs/RENAMING.md when the final name is decided.
abstract final class AppConstants {
  static const String appName = 'App Core';

  /// Number of items requested per page from list endpoints.
  static const int defaultPageSize = 20;
}
