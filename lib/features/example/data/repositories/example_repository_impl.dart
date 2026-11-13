import 'package:app_core/core/error/error_mapper.dart';
import 'package:app_core/core/error/failure.dart';
import 'package:app_core/core/network/network_info.dart';
import 'package:app_core/core/utils/typedefs.dart';
import 'package:app_core/features/example/data/datasources/example_local_data_source.dart';
import 'package:app_core/features/example/data/datasources/example_remote_data_source.dart';
import 'package:app_core/features/example/domain/entities/example_item.dart';
import 'package:app_core/features/example/domain/repositories/example_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Online: fetch from the API and refresh the cache.
/// Offline: serve the cache, or a [NetworkFailure] when there is none.
/// Every exception is mapped to a typed [Failure] here.
class ExampleRepositoryImpl implements ExampleRepository {
  const new({
    required ExampleRemoteDataSource remoteDataSource,
    required ExampleLocalDataSource localDataSource,
    required this._networkInfo,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final ExampleRemoteDataSource _remote;
  final ExampleLocalDataSource _local;
  final NetworkInfo _networkInfo;

  @override
  FutureEither<List<ExampleItem>> getItems() async {
    try {
      if (!await _networkInfo.isConnected) return await _fromCache();
      final models = await _remote.fetchItems();
      await _local.cacheItems(models);
      return Right(models.map((m) => m.toEntity()).toList());
    } on Object catch (e) {
      return Left(ErrorMapper.toFailure(e));
    }
  }

  Future<Either<Failure, List<ExampleItem>>> _fromCache() async {
    try {
      final models = await _local.getCachedItems();
      return Right(models.map((m) => m.toEntity()).toList());
    } on Object {
      return const Left(Failure.network());
    }
  }
}
