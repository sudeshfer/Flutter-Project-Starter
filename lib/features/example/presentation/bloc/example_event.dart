part of 'example_bloc.dart';

@freezed
sealed class ExampleEvent with _$ExampleEvent {
  /// Initial load and retry. Handled with `droppable()`.
  const factory started() = ExampleStarted;

  /// Pull-to-refresh. Handled with `restartable()`.
  const factory refreshed() = ExampleRefreshed;
}
