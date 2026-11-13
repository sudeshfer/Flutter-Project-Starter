import 'dart:convert';

import 'package:app_core/core/constants/storage_keys.dart';
import 'package:app_core/core/error/exceptions.dart';
import 'package:app_core/core/storage/key_value_storage.dart';
import 'package:app_core/core/utils/typedefs.dart';
import 'package:app_core/features/example/data/models/example_item_model.dart';

abstract interface class ExampleLocalDataSource {
  /// Throws a [CacheException] when nothing is cached.
  Future<List<ExampleItemModel>> getCachedItems();

  Future<void> cacheItems(List<ExampleItemModel> items);
}

class ExampleLocalDataSourceImpl implements ExampleLocalDataSource {
  const new(this._storage);

  final KeyValueStorage _storage;

  @override
  Future<List<ExampleItemModel>> getCachedItems() async {
    final raw = await _storage.getString(StorageKeys.exampleItemsCache);
    if (raw == null) throw const CacheException('No cached example items');
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<JsonMap>().map(ExampleItemModel.fromJson).toList();
  }

  @override
  Future<void> cacheItems(List<ExampleItemModel> items) => _storage.setString(
    StorageKeys.exampleItemsCache,
    jsonEncode(items.map((e) => e.toJson()).toList()),
  );
}
