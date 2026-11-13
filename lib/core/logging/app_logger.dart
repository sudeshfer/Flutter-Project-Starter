/// Logging abstraction used across the app.
///
/// Never import `package:logger` outside `core/logging`; depend on this
/// interface instead so the backend can be swapped (or mocked in tests).
abstract interface class AppLogger {
  void verbose(String message);
  void debug(String message);
  void info(String message);
  void warning(String message, {Object? error, StackTrace? stackTrace});
  void error(String message, {Object? error, StackTrace? stackTrace});
}
