import 'package:freezed_annotation/freezed_annotation.dart';

part 'example_item.freezed.dart';

/// Domain entity. Pure Dart: no Flutter, JSON or framework concerns.
@freezed
abstract class ExampleItem with _$ExampleItem {
  const factory({
    required int id,
    required int userId,
    required String title,
    required String body,
  }) = _ExampleItem;
}
