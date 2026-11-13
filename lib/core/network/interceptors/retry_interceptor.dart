import 'package:app_core/core/logging/app_logger.dart';
import 'package:dio/dio.dart';

/// Retries idempotent (GET) requests that failed because of a transient
/// network problem, with a simple linear backoff.
class RetryInterceptor extends Interceptor {
  new({
    required this._dio,
    required this._logger,
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 500),
  });

  final Dio _dio;
  final AppLogger _logger;
  final int maxRetries;
  final Duration baseDelay;

  static const String _attemptKey = 'retry_attempt';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;

    if (!_shouldRetry(err) || attempt >= maxRetries) {
      return handler.next(err);
    }

    final next = attempt + 1;
    _logger.info('Retrying ${options.method} ${options.uri} ($next)');
    await Future<void>.delayed(baseDelay * next);
    options.extra[_attemptKey] = next;

    try {
      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.requestOptions.method.toUpperCase() != 'GET') return false;
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      DioExceptionType.badResponse => (err.response?.statusCode ?? 0) >= 500,
      _ => false,
    };
  }
}
