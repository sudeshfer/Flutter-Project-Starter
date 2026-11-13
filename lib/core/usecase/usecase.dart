import 'package:app_core/core/utils/typedefs.dart';
import 'package:equatable/equatable.dart';

/// Base class for use cases. One public `call` per use case.
///
/// ```dart
/// final result = await getExampleItems(const NoParams());
/// ```
abstract interface class UseCase<T, Params> {
  FutureEither<T> call(Params params);
}

/// Use for use cases that take no input.
final class NoParams extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}
