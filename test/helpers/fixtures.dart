import 'package:app_core/features/example/data/models/example_item_model.dart';
import 'package:app_core/features/example/domain/entities/example_item.dart';

/// Shape returned by jsonplaceholder `/posts`.
const Map<String, dynamic> exampleItemJson = {
  'userId': 1,
  'id': 7,
  'title': 'Title',
  'body': 'Body',
};

const ExampleItemModel exampleItemModel = ExampleItemModel(
  id: 7,
  userId: 1,
  title: 'Title',
  body: 'Body',
);

const ExampleItem exampleItem = ExampleItem(
  id: 7,
  userId: 1,
  title: 'Title',
  body: 'Body',
);
