import 'package:app_core/features/example/domain/entities/example_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'example_item_model.freezed.dart';
part 'example_item_model.g.dart';

/// API model. `build.yaml` sets `field_rename: snake` by default; this API
/// uses camelCase for `userId`, so it is overridden with `@JsonKey`.
@freezed
abstract class ExampleItemModel with _$ExampleItemModel {
  const factory({
    required int id,
    @JsonKey(name: 'userId') required int userId,
    required String title,
    @Default('') String body,
  }) = _ExampleItemModel;

  const new _();

  factory fromJson(Map<String, dynamic> json) =>
      _$ExampleItemModelFromJson(json);

  ExampleItem toEntity() =>
      ExampleItem(id: id, userId: userId, title: title, body: body);
}
