part of 'example_bloc.dart';

/// Sealed-union state (see docs/ARCHITECTURE.md → "Bloc conventions").
/// An empty list in [ExampleLoaded] is the empty state.
@freezed
sealed class ExampleState with _$ExampleState {
  const factory initial() = ExampleInitial;
  const factory loading() = ExampleLoading;
  const factory loaded(List<ExampleItem> items) = ExampleLoaded;
  const factory failure(Failure failure) = ExampleFailure;
}
