import 'package:app_core/app/di/injection_container.dart';

/// Call in `tearDown` of any test that touches `sl`.
Future<void> resetGetIt() => resetDependencies();
