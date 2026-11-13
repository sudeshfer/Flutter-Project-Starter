import 'package:app_core/core/error/failure.dart';
import 'package:app_core/core/usecase/usecase.dart';
import 'package:app_core/features/example/domain/entities/example_item.dart';
import 'package:app_core/features/example/domain/usecases/get_example_items_use_case.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'example_bloc.freezed.dart';
part 'example_event.dart';
part 'example_state.dart';

/// Depends on use cases only — never on repositories or data sources.
class ExampleBloc extends Bloc<ExampleEvent, ExampleState> {
  new({required this._getExampleItems}) : super(const ExampleState.initial()) {
    on<ExampleStarted>(_onStarted, transformer: droppable());
    on<ExampleRefreshed>(_onRefreshed, transformer: restartable());
  }

  final GetExampleItemsUseCase _getExampleItems;

  Future<void> _onStarted(
    ExampleStarted event,
    Emitter<ExampleState> emit,
  ) async {
    emit(const ExampleState.loading());
    await _load(emit);
  }

  /// Keeps the current content on screen while refreshing (no `loading`).
  Future<void> _onRefreshed(
    ExampleRefreshed event,
    Emitter<ExampleState> emit,
  ) => _load(emit);

  Future<void> _load(Emitter<ExampleState> emit) async {
    final result = await _getExampleItems(const NoParams());
    emit(result.match(ExampleState.failure, ExampleState.loaded));
  }
}
