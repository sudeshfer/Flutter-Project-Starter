import 'package:app_core/app/app.dart';
import 'package:app_core/app/di/injection_container.dart';
import 'package:app_core/core/bloc/app_bloc_observer.dart';
import 'package:app_core/core/config/app_config.dart';
import 'package:app_core/core/config/flavor.dart';
import 'package:app_core/core/logging/app_logger.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Shared startup for every flavor. `main_<flavor>.dart` only calls this.
///
/// This is the composition root, so it may read from `sl`.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromFlavor(flavor);
  await initDependencies(config);

  final logger = sl<AppLogger>();

  Bloc.observer = AppBlocObserver(
    logger: logger,
    logTransitions: config.logBlocTransitions,
  );

  FlutterError.onError = (details) {
    logger.error(
      'FlutterError: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
    );
    if (kDebugMode) FlutterError.presentError(details);
    _reportError(config, details.exception, details.stack, fatal: false);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error('Uncaught error', error: error, stackTrace: stack);
    _reportError(config, error, stack, fatal: true);
    return true;
  };

  logger.info('Starting ${config.appName} (${flavor.name})');

  runApp(App(config: config, router: sl<GoRouter>()));
}

void _reportError(
  AppConfig config,
  Object error,
  StackTrace? stack, {
  required bool fatal,
}) {
  if (!config.crashReportingEnabled) return;
  // TODO(crash-reporting): forward to Crashlytics or Sentry here, e.g.
  // FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
  // Initialise the SDK in bootstrap() before initDependencies(). It is
  // enabled for qa, staging, uat and prod; dev is excluded via
  // Flavor.isCrashReportingEnabled.
}
