import 'package:app_core/core/error/failure.dart';
import 'package:app_core/features/example/presentation/bloc/example_bloc.dart';
import 'package:app_core/features/example/presentation/pages/example_page.dart';
import 'package:app_core/features/example/presentation/widgets/example_item_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  late MockExampleBloc bloc;

  setUp(() => bloc = MockExampleBloc());

  Future<void> pumpPage(WidgetTester tester, ExampleState state) async {
    when(() => bloc.state).thenReturn(state);
    await tester.pumpApp(
      BlocProvider<ExampleBloc>.value(value: bloc, child: const ExamplePage()),
    );
  }

  testWidgets('shows a loader while loading', (tester) async {
    await pumpPage(tester, const ExampleState.loading());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows a loader in the initial state', (tester) async {
    await pumpPage(tester, const ExampleState.initial());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the error and retries on tap', (tester) async {
    await pumpPage(
      tester,
      const ExampleState.failure(Failure.server(message: 'Server down')),
    );

    expect(find.text('Server down'), findsOneWidget);
    await tester.tap(find.text('Retry'));

    verify(() => bloc.add(const ExampleEvent.started())).called(1);
  });

  testWidgets('shows the empty state for an empty list', (tester) async {
    await pumpPage(tester, const ExampleState.loaded([]));
    expect(find.text('Nothing here yet.'), findsOneWidget);
    expect(find.byType(ExampleItemTile), findsNothing);
  });

  testWidgets('shows items and the item count', (tester) async {
    await pumpPage(tester, const ExampleState.loaded([exampleItem]));

    expect(find.byType(ExampleItemTile), findsOneWidget);
    expect(find.text(exampleItem.title), findsOneWidget);
    expect(find.text('1 item'), findsOneWidget);
  });
}
