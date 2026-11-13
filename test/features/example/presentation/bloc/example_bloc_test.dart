import 'dart:async';

import 'package:app_core/core/error/failure.dart';
import 'package:app_core/core/usecase/usecase.dart';
import 'package:app_core/core/utils/typedefs.dart';
import 'package:app_core/features/example/domain/entities/example_item.dart';
import 'package:app_core/features/example/presentation/bloc/example_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockGetExampleItemsUseCase getItems;

  const failure = Failure.network();
  const items = [exampleItem];

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() => getItems = MockGetExampleItemsUseCase());

  ExampleBloc build() => ExampleBloc(getExampleItems: getItems);

  void stub(Either<Failure, List<ExampleItem>> result) =>
      when(() => getItems(any())).thenAnswer((_) async => result);

  test('initial state is ExampleState.initial', () {
    expect(build().state, const ExampleState.initial());
  });

  group('ExampleStarted', () {
    blocTest<ExampleBloc, ExampleState>(
      'emits [loading, loaded] on success',
      setUp: () => stub(const Right(items)),
      build: build,
      act: (bloc) => bloc.add(const ExampleEvent.started()),
      expect: () => const [ExampleState.loading(), ExampleState.loaded(items)],
      verify: (_) => verify(() => getItems(const NoParams())).called(1),
    );

    blocTest<ExampleBloc, ExampleState>(
      'emits [loading, loaded([])] when there are no items',
      setUp: () => stub(const Right([])),
      build: build,
      act: (bloc) => bloc.add(const ExampleEvent.started()),
      expect: () => const [ExampleState.loading(), ExampleState.loaded([])],
    );

    blocTest<ExampleBloc, ExampleState>(
      'emits [loading, failure] on failure',
      setUp: () => stub(const Left(failure)),
      build: build,
      act: (bloc) => bloc.add(const ExampleEvent.started()),
      expect: () => const [
        ExampleState.loading(),
        ExampleState.failure(failure),
      ],
    );

    final pending = Completer<Either<Failure, List<ExampleItem>>>();
    blocTest<ExampleBloc, ExampleState>(
      'is droppable: events added while loading are ignored',
      setUp: () =>
          when(() => getItems(any())).thenAnswer((_) => pending.future),
      build: build,
      act: (bloc) async {
        bloc
          ..add(const ExampleEvent.started())
          ..add(const ExampleEvent.started());
        await Future<void>.delayed(Duration.zero);
        pending.complete(const Right(items));
      },
      expect: () => const [ExampleState.loading(), ExampleState.loaded(items)],
      verify: (_) => verify(() => getItems(any())).called(1),
    );
  });

  group('ExampleRefreshed', () {
    blocTest<ExampleBloc, ExampleState>(
      'emits [loaded] without a loading state on success',
      setUp: () => stub(const Right(items)),
      build: build,
      seed: () => const ExampleState.loaded([]),
      act: (bloc) => bloc.add(const ExampleEvent.refreshed()),
      expect: () => const [ExampleState.loaded(items)],
    );

    blocTest<ExampleBloc, ExampleState>(
      'emits [failure] on failure',
      setUp: () => stub(const Left(failure)),
      build: build,
      seed: () => const ExampleState.loaded(items),
      act: (bloc) => bloc.add(const ExampleEvent.refreshed()),
      expect: () => const [ExampleState.failure(failure)],
    );

    final slow = Completer<Either<Failure, List<ExampleItem>>>();
    blocTest<ExampleBloc, ExampleState>(
      'is restartable: only the latest refresh emits',
      setUp: () {
        final answers = <FutureEither<List<ExampleItem>>>[
          slow.future,
          Future.value(const Right([])),
        ];
        when(() => getItems(any())).thenAnswer((_) => answers.removeAt(0));
      },
      build: build,
      act: (bloc) async {
        bloc
          ..add(const ExampleEvent.refreshed())
          ..add(const ExampleEvent.refreshed());
        await Future<void>.delayed(Duration.zero);
        slow.complete(const Right(items));
      },
      expect: () => const [ExampleState.loaded([])],
    );
  });
}
