import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Typed failures returned (inside `Either`) by repositories and use cases.
///
/// Blocs and the UI only ever see a [Failure], never a raw exception.
@freezed
sealed class Failure with _$Failure {
  const factory server({required String message, int? statusCode}) =
      ServerFailure;

  const factory network({
    @Default('No internet connection. Check your connection and try again.')
    String message,
  }) = NetworkFailure;

  const factory unauthorized({
    @Default('Your session has expired. Please sign in again.') String message,
  }) = UnauthorizedFailure;

  const factory cache({@Default('No cached data.') String message}) =
      CacheFailure;

  const factory parsing({
    @Default('Received data in an unexpected format.') String message,
  }) = ParsingFailure;

  const factory unexpected({
    @Default('Something went wrong. Please try again.') String message,
  }) = UnexpectedFailure;
}
