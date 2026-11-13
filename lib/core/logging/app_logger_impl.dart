import 'package:app_core/core/logging/app_logger.dart';
import 'package:app_core/core/logging/log_level.dart';
import 'package:logger/logger.dart';

/// [AppLogger] backed by `package:logger`.
///
/// Uses a [ProductionFilter] so the configured [LogLevel] is respected in
/// release builds too (staging/prod keep warnings and errors).
class AppLoggerImpl implements AppLogger {
  new({required LogLevel level, Logger? logger})
    : _logger =
          logger ??
          Logger(
            level: _toLoggerLevel(level),
            filter: ProductionFilter(),
            printer: PrettyPrinter(methodCount: 0, dateTimeFormat: _time),
          );

  final Logger _logger;

  static const DateTimeFormatter _time = DateTimeFormat.onlyTimeAndSinceStart;

  static Level _toLoggerLevel(LogLevel level) => switch (level) {
    LogLevel.verbose => Level.trace,
    LogLevel.debug => Level.debug,
    LogLevel.info => Level.info,
    LogLevel.warning => Level.warning,
    LogLevel.error => Level.error,
    LogLevel.off => Level.off,
  };

  @override
  void verbose(String message) => _logger.t(message);

  @override
  void debug(String message) => _logger.d(message);

  @override
  void info(String message) => _logger.i(message);

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
