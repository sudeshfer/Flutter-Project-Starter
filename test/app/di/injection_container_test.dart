import 'package:app_core/app/di/injection_container.dart';
import 'package:app_core/core/config/app_config.dart';
import 'package:app_core/core/config/environment_values.dart';
import 'package:app_core/core/config/flavor.dart';
import 'package:app_core/core/storage/key_value_storage.dart';
import 'package:app_core/features/example/domain/repositories/example_repository.dart';
import 'package:app_core/features/example/domain/usecases/get_example_items_use_case.dart';
import 'package:app_core/features/example/presentation/bloc/example_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/get_it_helper.dart';
import '../../helpers/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await initDependencies(
      AppConfig.fromFlavor(
        Flavor.dev,
        env: const EnvironmentValues(apiBaseUrl: 'https://test'),
      ),
    );
    // Swap platform-backed services for fakes.
    sl
      ..unregister<KeyValueStorage>()
      ..registerLazySingleton<KeyValueStorage>(MockKeyValueStorage.new);
  });

  tearDown(resetGetIt);

  test('blocs are factories (new instance each time)', () async {
    final a = sl<ExampleBloc>();
    final b = sl<ExampleBloc>();
    expect(identical(a, b), isFalse);
    await a.close();
    await b.close();
  });

  test('repositories, use cases and router are singletons', () {
    expect(identical(sl<ExampleRepository>(), sl<ExampleRepository>()), isTrue);
    expect(
      identical(sl<GetExampleItemsUseCase>(), sl<GetExampleItemsUseCase>()),
      isTrue,
    );
    expect(identical(sl<GoRouter>(), sl<GoRouter>()), isTrue);
  });
}
