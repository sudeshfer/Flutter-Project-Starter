import 'package:app_core/core/error/exceptions.dart';
import 'package:app_core/core/error/failure.dart';
import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

/// Maps any error thrown below the repository into a typed [Failure].
abstract final class ErrorMapper {
  static Failure toFailure(Object error) => switch (error) {
    ServerException(:final message, :final statusCode) => Failure.server(
      message: message,
      statusCode: statusCode,
    ),
    NetworkException() => const Failure.network(),
    UnauthorizedException() => const Failure.unauthorized(),
    CacheException(:final message) => Failure.cache(message: message),
    ParsingException() ||
    CheckedFromJsonException() ||
    FormatException() ||
    TypeError() => const Failure.parsing(),
    DioException() => _fromDio(error),
    _ => const Failure.unexpected(),
  };

  static Failure _fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const Failure.network();
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401) return const Failure.unauthorized();
        return Failure.server(
          message: 'Server error${code == null ? '' : ' ($code)'}.',
          statusCode: code,
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        final inner = e.error;
        if (inner != null && inner is! DioException) return toFailure(inner);
        return const Failure.unexpected();
    }
  }
}
