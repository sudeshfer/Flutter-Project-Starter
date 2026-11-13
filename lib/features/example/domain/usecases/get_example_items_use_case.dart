import 'package:app_core/core/usecase/usecase.dart';
import 'package:app_core/core/utils/typedefs.dart';
import 'package:app_core/features/example/domain/entities/example_item.dart';
import 'package:app_core/features/example/domain/repositories/example_repository.dart';

/// Returns the list of example items.
class GetExampleItemsUseCase implements UseCase<List<ExampleItem>, NoParams> {
  const new(this._repository);

  final ExampleRepository _repository;

  @override
  FutureEither<List<ExampleItem>> call(NoParams params) =>
      _repository.getItems();
}
