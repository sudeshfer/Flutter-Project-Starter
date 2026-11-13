import 'package:app_core/core/logging/app_logger.dart';
import 'package:dio/dio.dart';

/// Logs requests/responses at debug level (filtered out in staging/prod by
/// the logger level). Never logs headers, so tokens don't leak.
class LoggingInterceptor extends Interceptor {
  new(this._logger);

  final AppLogger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.debug('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final req = response.requestOptions;
    _logger.debug('← ${response.statusCode} ${req.method} ${req.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final req = err.requestOptions;
    _logger.warning(
      '✕ ${err.response?.statusCode ?? err.type.name} ${req.method} ${req.uri}',
      error: err.message,
    );
    handler.next(err);
  }
}
