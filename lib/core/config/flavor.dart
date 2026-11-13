import 'package:app_core/core/constants/app_constants.dart';
import 'package:app_core/core/logging/log_level.dart';

/// Build flavors. Each one has its own entry point (`lib/main_<flavor>.dart`),
/// env file (`env/<flavor>.json`), app name and bundle/application ID.
enum Flavor {
  dev,
  qa,
  staging,
  uat,
  prod;

  bool get isProd => this == Flavor.prod;

  /// Debug tooling (router diagnostics, Bloc transition logs, verbose network
  /// logs) is enabled for dev and qa only.
  bool get isDebugTools => this == Flavor.dev || this == Flavor.qa;

  /// Crash reporting is planned for every flavor except dev.
  bool get isCrashReportingEnabled => this != Flavor.dev;

  /// Short label shown in the in-app banner and launcher icon ribbon.
  String get label => switch (this) {
    Flavor.dev => 'DEV',
    Flavor.qa => 'QA',
    Flavor.staging => 'STG',
    Flavor.uat => 'UAT',
    Flavor.prod => '',
  };

  /// Human-readable app name, e.g. `App Core DEV`.
  String get appName =>
      isProd ? AppConstants.appName : '${AppConstants.appName} $label';

  LogLevel get logLevel => switch (this) {
    Flavor.dev => LogLevel.verbose,
    Flavor.qa => LogLevel.info,
    Flavor.staging || Flavor.uat || Flavor.prod => LogLevel.warning,
  };
}
