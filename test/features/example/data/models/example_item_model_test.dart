import 'package:app_core/features/example/data/models/example_item_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../helpers/fixtures.dart';

void main() {
  group('ExampleItemModel', () {
    test('fromJson parses the API shape', () {
      expect(ExampleItemModel.fromJson(exampleItemJson), exampleItemModel);
    });

    test('toJson round-trips with the API keys', () {
      expect(exampleItemModel.toJson(), exampleItemJson);
    });

    test('body defaults to empty string when missing', () {
      final json = Map<String, dynamic>.of(exampleItemJson)..remove('body');
      expect(ExampleItemModel.fromJson(json).body, isEmpty);
    });

    test('throws CheckedFromJsonException on invalid JSON', () {
      final json = Map<String, dynamic>.of(exampleItemJson)..['id'] = 'x';
      expect(
        () => ExampleItemModel.fromJson(json),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });

    test('toEntity maps every field', () {
      expect(exampleItemModel.toEntity(), exampleItem);
    });
  });
}
