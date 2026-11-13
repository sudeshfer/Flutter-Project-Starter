/// Exceptions thrown by the data layer (data sources, network, storage).
///
/// They never leave the repository: `ErrorMapper` turns them into a
/// `Failure`.
sealed class AppException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'AppException: $message';
}

final class ServerException extends AppException {
  const new(super.message, {this.statusCode});

  final int? statusCode;
}

final class NetworkException extends AppException {
  const new([super.message = 'No internet connection']);
}

final class UnauthorizedException extends AppException {
  const new([super.message = 'Unauthorized']);
}

final class CacheException extends AppException {
  const new([super.message = 'Cache error']);
}

final class ParsingException extends AppException {
  const new([super.message = 'Could not parse response']);
}
