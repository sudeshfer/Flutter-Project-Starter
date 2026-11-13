import 'package:equatable/equatable.dart';

/// Raw values loaded from `--dart-define-from-file=env/<flavor>.json`.
///
/// Never hardcode secrets or URLs in Dart: add a key to every
/// `env/*.example.json`, then read it here.
final class EnvironmentValues extends Equatable {
  const new({
    required this.apiBaseUrl,
    this.apiKey = '',
    this.connectTimeoutMs = defaultTimeoutMs,
    this.receiveTimeoutMs = defaultTimeoutMs,
  });

  /// Reads the compile-time dart-defines.
  const new fromDartDefines()
    : apiBaseUrl = const String.fromEnvironment('API_BASE_URL'),
      apiKey = const String.fromEnvironment('API_KEY'),
      connectTimeoutMs = const int.fromEnvironment(
        'CONNECT_TIMEOUT_MS',
        defaultValue: defaultTimeoutMs,
      ),
      receiveTimeoutMs = const int.fromEnvironment(
        'RECEIVE_TIMEOUT_MS',
        defaultValue: defaultTimeoutMs,
      );

  static const int defaultTimeoutMs = 15000;

  final String apiBaseUrl;
  final String apiKey;
  final int connectTimeoutMs;
  final int receiveTimeoutMs;

  @override
  List<Object?> get props => [
    apiBaseUrl,
    apiKey,
    connectTimeoutMs,
    receiveTimeoutMs,
  ];
}
