import 'package:app_core/app/router/app_router.dart';
import 'package:app_core/app/router/guards/auth_guard.dart';
import 'package:app_core/core/config/app_config.dart';
import 'package:app_core/core/logging/app_logger.dart';
import 'package:app_core/core/logging/app_logger_impl.dart';
import 'package:app_core/core/network/dio_client.dart';
import 'package:app_core/core/network/network_info.dart';
import 'package:app_core/core/storage/key_value_storage.dart';
import 'package:app_core/core/storage/secure_storage.dart';
import 'package:app_core/features/example/example_injection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The single service locator. Use it ONLY in DI files, route builders and
/// the bootstrap composition root; everywhere else use constructor injection.
final GetIt sl = GetIt.instance;

/// Registers core services first, then each feature's dependencies.
///
/// Lifetimes: config → singleton; services, data sources, repositories and
/// use cases → lazy singleton; blocs/cubits → factory.
Future<void> initDependencies(AppConfig config) async {
  sl
    // Config
    ..registerSingleton<AppConfig>(config)
    // Logging
    ..registerLazySingleton<AppLogger>(
      () => AppLoggerImpl(level: config.logLevel),
    )
    // Storage
    ..registerLazySingleton<FlutterSecureStorage>(FlutterSecureStorage.new)
    ..registerLazySingleton<SecureStorage>(() => SecureStorageImpl(sl()))
    ..registerLazySingleton<SharedPreferencesAsync>(SharedPreferencesAsync.new)
    ..registerLazySingleton<KeyValueStorage>(() => KeyValueStorageImpl(sl()))
    // Network
    ..registerLazySingleton<Connectivity>(Connectivity.new)
    ..registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()))
    ..registerLazySingleton<Dio>(
      () => DioClient.create(config: sl(), logger: sl(), secureStorage: sl()),
    )
    // Router
    ..registerLazySingleton<AuthGuard>(AuthGuard.new)
    ..registerLazySingleton<GoRouter>(
      () => createAppRouter(config: sl(), authGuard: sl()),
    );

  // Features — each feature owns its registrations.
  registerExampleDependencies(sl);

  await sl.allReady();
}

/// Clears every registration. Use in tests (`tearDown`).
Future<void> resetDependencies() => sl.reset();
