import 'package:app_core/core/constants/storage_keys.dart';
import 'package:app_core/core/storage/secure_storage.dart';
import 'package:dio/dio.dart';

/// Adds `Authorization: Bearer <token>` when an access token is stored.
class AuthInterceptor extends Interceptor {
  new(this._secureStorage);

  final SecureStorage _secureStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(StorageKeys.accessToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // TODO(auth): on 401, refresh the token and retry, or sign the user out.
    handler.next(err);
  }
}
