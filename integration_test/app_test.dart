// Run with:
// fvm flutter test integration_test --flavor dev \
//   --dart-define-from-file=env/dev.json
import 'package:app_core/bootstrap.dart';
import 'package:app_core/core/config/flavor.dart';
import 'package:app_core/features/example/presentation/pages/example_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dev flavor boots to the example page', (tester) async {
    await bootstrap(Flavor.dev);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.byType(ExamplePage), findsOneWidget);
  });
}
