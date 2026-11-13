import 'package:app_core/core/config/app_config.dart';
import 'package:app_core/core/logging/app_logger.dart';
import 'package:app_core/core/network/interceptors/auth_interceptor.dart';
import 'package:app_core/core/network/interceptors/logging_interceptor.dart';
import 'package:app_core/core/network/interceptors/retry_interceptor.dart';
import 'package:app_core/core/storage/secure_storage.dart';
import 'package:dio/dio.dart';

/// Builds the single app-wide [Dio] instance.
abstract final class DioClient {
  static Dio create({
    required AppConfig config,
    required AppLogger logger,
    required SecureStorage secureStorage,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          if (config.apiKey.isNotEmpty) 'x-api-key': config.apiKey,
        },
      ),
    );
    dio.interceptors.addAll([
      AuthInterceptor(secureStorage),
      RetryInterceptor(dio: dio, logger: logger),
      LoggingInterceptor(logger),
    ]);
    return dio;
  }
}
