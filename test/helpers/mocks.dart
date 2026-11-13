import 'package:app_core/core/network/network_info.dart';
import 'package:app_core/core/storage/key_value_storage.dart';
import 'package:app_core/features/example/data/datasources/example_local_data_source.dart';
import 'package:app_core/features/example/data/datasources/example_remote_data_source.dart';
import 'package:app_core/features/example/domain/repositories/example_repository.dart';
import 'package:app_core/features/example/domain/usecases/get_example_items_use_case.dart';
import 'package:app_core/features/example/presentation/bloc/example_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

// Core
class MockNetworkInfo extends Mock implements NetworkInfo;

class MockKeyValueStorage extends Mock implements KeyValueStorage;

// Example feature
class MockExampleRemoteDataSource extends Mock
    implements ExampleRemoteDataSource;

class MockExampleLocalDataSource extends Mock implements ExampleLocalDataSource;

class MockExampleRepository extends Mock implements ExampleRepository;

class MockGetExampleItemsUseCase extends Mock implements GetExampleItemsUseCase;

class MockExampleBloc extends MockBloc<ExampleEvent, ExampleState>
    implements ExampleBloc;
