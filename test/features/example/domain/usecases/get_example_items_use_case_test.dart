import 'package:app_core/core/error/failure.dart';
import 'package:app_core/core/usecase/usecase.dart';
import 'package:app_core/features/example/domain/entities/example_item.dart';
import 'package:app_core/features/example/domain/usecases/get_example_items_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockExampleRepository repository;
  late GetExampleItemsUseCase useCase;

  setUp(() {
    repository = MockExampleRepository();
    useCase = GetExampleItemsUseCase(repository);
  });

  test('returns the items from the repository', () async {
    when(repository.getItems)
        .thenAnswer((_) async => const Right([exampleItem]));

    final result = await useCase(const NoParams());

    expect(result.getRight().toNullable(), [exampleItem]);
    verify(repository.getItems).called(1);
  });

  test('passes the failure through', () async {
    const failure = Failure.server(message: 'boom');
    when(
      repository.getItems,
    ).thenAnswer((_) async => const Left<Failure, List<ExampleItem>>(failure));

    final result = await useCase(const NoParams());

    expect(result.getLeft().toNullable(), failure);
  });
}
