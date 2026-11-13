import 'package:app_core/core/constants/app_constants.dart';
import 'package:app_core/core/error/exceptions.dart';
import 'package:app_core/core/utils/typedefs.dart';
import 'package:app_core/features/example/data/models/example_item_model.dart';
import 'package:dio/dio.dart';

abstract interface class ExampleRemoteDataSource {
  /// Throws a [DioException] or [ParsingException] on failure.
  Future<List<ExampleItemModel>> fetchItems();
}

class ExampleRemoteDataSourceImpl implements ExampleRemoteDataSource {
  const new(this._dio);

  final Dio _dio;

  static const String _path = '/posts';

  @override
  Future<List<ExampleItemModel>> fetchItems() async {
    final response = await _dio.get<List<dynamic>>(
      _path,
      queryParameters: {'_limit': AppConstants.defaultPageSize},
    );
    final data = response.data;
    if (data == null) throw const ParsingException('Empty response body');
    return data
        .cast<JsonMap>()
        .map(ExampleItemModel.fromJson)
        .toList(growable: false);
  }
}
