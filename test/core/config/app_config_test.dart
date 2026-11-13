import 'package:app_core/core/config/app_config.dart';
import 'package:app_core/core/config/environment_values.dart';
import 'package:app_core/core/config/flavor.dart';
import 'package:app_core/core/logging/log_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const env = EnvironmentValues(
    apiBaseUrl: 'https://api.example.com',
    apiKey: 'key',
    connectTimeoutMs: 1000,
    receiveTimeoutMs: 2000,
  );

  group('Flavor', () {
    test('has exactly dev, qa, staging, uat, prod', () {
      expect(Flavor.values, [
        Flavor.dev,
        Flavor.qa,
        Flavor.staging,
        Flavor.uat,
        Flavor.prod,
      ]);
    });

    test('isProd only for prod', () {
      expect(Flavor.values.where((f) => f.isProd), [Flavor.prod]);
    });

    test('isDebugTools only for dev and qa', () {
      expect(Flavor.values.where((f) => f.isDebugTools), [
        Flavor.dev,
        Flavor.qa,
      ]);
    });
  });

  group('AppConfig.fromFlavor', () {
    // flavor: (appName, logLevel, debugTools, crashReporting, banner)
    const expected = {
      Flavor.dev: ('App Core DEV', LogLevel.verbose, true, false, true),
      Flavor.qa: ('App Core QA', LogLevel.info, true, true, true),
      Flavor.staging: ('App Core STG', LogLevel.warning, false, true, true),
      Flavor.uat: ('App Core UAT', LogLevel.warning, false, true, true),
      Flavor.prod: ('App Core', LogLevel.warning, false, true, false),
    };

    for (final MapEntry(key: flavor, value: e) in expected.entries) {
      test('${flavor.name} resolves the correct settings', () {
        final config = AppConfig.fromFlavor(flavor, env: env);

        expect(config.flavor, flavor);
        expect(config.appName, e.$1);
        expect(config.logLevel, e.$2);
        expect(config.enableRouterDiagnostics, e.$3);
        expect(config.logBlocTransitions, e.$3);
        expect(config.crashReportingEnabled, e.$4);
        expect(config.showFlavorBanner, e.$5);
        expect(config.apiBaseUrl, 'https://api.example.com');
        expect(config.apiKey, 'key');
        expect(config.connectTimeout, const Duration(seconds: 1));
        expect(config.receiveTimeout, const Duration(seconds: 2));
      });
    }

    test('throws when API_BASE_URL is missing', () {
      expect(() => AppConfig.fromFlavor(Flavor.dev), throwsStateError);
    });
  });
}
