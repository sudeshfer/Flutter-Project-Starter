import 'package:app_core/features/example/data/datasources/example_local_data_source.dart';
import 'package:app_core/features/example/data/datasources/example_remote_data_source.dart';
import 'package:app_core/features/example/data/repositories/example_repository_impl.dart';
import 'package:app_core/features/example/domain/repositories/example_repository.dart';
import 'package:app_core/features/example/domain/usecases/get_example_items_use_case.dart';
import 'package:app_core/features/example/presentation/bloc/example_bloc.dart';
import 'package:get_it/get_it.dart';

/// Registers everything the example feature needs.
/// Called from `initDependencies()`.
void registerExampleDependencies(GetIt sl) {
  sl
    // Data sources
    ..registerLazySingleton<ExampleRemoteDataSource>(
      () => ExampleRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<ExampleLocalDataSource>(
      () => ExampleLocalDataSourceImpl(sl()),
    )
    // Repositories (always registered against the abstract type)
    ..registerLazySingleton<ExampleRepository>(
      () => ExampleRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ),
    )
    // Use cases
    ..registerLazySingleton<GetExampleItemsUseCase>(
      () => GetExampleItemsUseCase(sl()),
    )
    // Blocs — ALWAYS factory
    ..registerFactory<ExampleBloc>(() => ExampleBloc(getExampleItems: sl()));
}
