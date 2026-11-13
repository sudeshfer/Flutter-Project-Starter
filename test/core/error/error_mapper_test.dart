import 'package:app_core/core/error/error_mapper.dart';
import 'package:app_core/core/error/exceptions.dart';
import 'package:app_core/core/error/failure.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final options = RequestOptions(path: '/x');

  DioException dio(DioExceptionType type, {int? status}) => DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<void>(requestOptions: options, statusCode: status),
  );

  group('ErrorMapper.toFailure', () {
    test('maps app exceptions', () {
      expect(
        ErrorMapper.toFailure(const ServerException('boom', statusCode: 500)),
        const Failure.server(message: 'boom', statusCode: 500),
      );
      expect(
        ErrorMapper.toFailure(const NetworkException()),
        isA<NetworkFailure>(),
      );
      expect(
        ErrorMapper.toFailure(const UnauthorizedException()),
        isA<UnauthorizedFailure>(),
      );
      expect(
        ErrorMapper.toFailure(const CacheException('none')),
        const Failure.cache(message: 'none'),
      );
      expect(
        ErrorMapper.toFailure(const ParsingException()),
        isA<ParsingFailure>(),
      );
    });

    test('maps Dio connection problems to NetworkFailure', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        expect(ErrorMapper.toFailure(dio(type)), isA<NetworkFailure>());
      }
    });

    test('maps 401 to UnauthorizedFailure and 5xx to ServerFailure', () {
      expect(
        ErrorMapper.toFailure(dio(DioExceptionType.badResponse, status: 401)),
        isA<UnauthorizedFailure>(),
      );
      expect(
        ErrorMapper.toFailure(dio(DioExceptionType.badResponse, status: 503)),
        isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 503),
      );
    });

    test('maps format errors to ParsingFailure', () {
      expect(
        ErrorMapper.toFailure(const FormatException()),
        isA<ParsingFailure>(),
      );
    });

    test('maps anything else to UnexpectedFailure', () {
      expect(ErrorMapper.toFailure(Exception('?')), isA<UnexpectedFailure>());
    });
  });
}
