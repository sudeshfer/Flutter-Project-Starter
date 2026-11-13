import 'package:app_core/core/utils/typedefs.dart';
import 'package:app_core/features/example/domain/entities/example_item.dart';

/// Contract implemented by the data layer.
abstract interface class ExampleRepository {
  FutureEither<List<ExampleItem>> getItems();
}
