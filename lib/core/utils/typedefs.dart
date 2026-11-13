import 'package:app_core/core/error/failure.dart';
import 'package:fpdart/fpdart.dart';

/// Return type of every repository method and use case.
typedef FutureEither<T> = Future<Either<Failure, T>>;

/// Decoded JSON object.
typedef JsonMap = Map<String, dynamic>;
