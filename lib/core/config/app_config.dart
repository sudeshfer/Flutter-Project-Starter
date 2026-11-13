import 'package:app_core/core/config/environment_values.dart';
import 'package:app_core/core/config/flavor.dart';
import 'package:app_core/core/logging/log_level.dart';
import 'package:equatable/equatable.dart';

/// Immutable runtime configuration, resolved once in `bootstrap.dart` from the
/// [Flavor] plus the dart-defines, then registered in get_it.
final class AppConfig extends Equatable {
  const new _({
    required this.flavor,
    required this.apiBaseUrl,
    required this.apiKey,
    required this.connectTimeout,
    required this.receiveTimeout,
  });

  /// Builds the config for [flavor]. [env] defaults to the dart-defines;
  /// pass it explicitly in tests.
  ///
  /// Throws a [StateError] when `API_BASE_URL` is missing, which almost
  /// always means `--dart-define-from-file` was not passed.
  factory fromFlavor(
    Flavor flavor, {
    EnvironmentValues env = const EnvironmentValues.fromDartDefines(),
  }) {
    if (env.apiBaseUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL is empty. Run with '
        '--dart-define-from-file=env/${flavor.name}.json',
      );
    }
    return AppConfig._(
      flavor: flavor,
      apiBaseUrl: env.apiBaseUrl,
      apiKey: env.apiKey,
      connectTimeout: Duration(milliseconds: env.connectTimeoutMs),
      receiveTimeout: Duration(milliseconds: env.receiveTimeoutMs),
    );
  }

  final Flavor flavor;
  final String apiBaseUrl;
  final String apiKey;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  String get appName => flavor.appName;
  LogLevel get logLevel => flavor.logLevel;
  bool get enableRouterDiagnostics => flavor.isDebugTools;
  bool get logBlocTransitions => flavor.isDebugTools;
  bool get crashReportingEnabled => flavor.isCrashReportingEnabled;
  bool get showFlavorBanner => !flavor.isProd;

  @override
  List<Object?> get props => [
    flavor,
    apiBaseUrl,
    apiKey,
    connectTimeout,
    receiveTimeout,
  ];
}
