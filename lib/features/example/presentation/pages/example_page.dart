import 'package:app_core/core/extensions/context_extensions.dart';
import 'package:app_core/features/example/presentation/bloc/example_bloc.dart';
import 'package:app_core/features/example/presentation/widgets/example_item_tile.dart';
import 'package:app_core/shared/widgets/app_loader.dart';
import 'package:app_core/shared/widgets/empty_view.dart';
import 'package:app_core/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Expects an [ExampleBloc] above it (provided by the route builder).
class ExamplePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.exampleTitle),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(24),
          child: _ItemCount(),
        ),
      ),
      body: BlocBuilder<ExampleBloc, ExampleState>(
        builder: (context, state) => switch (state) {
          ExampleInitial() ||
          ExampleLoading() => AppLoader(semanticsLabel: context.l10n.loading),
          ExampleFailure(:final failure) => ErrorView(
            message: failure.message,
            onRetry: () =>
                context.read<ExampleBloc>().add(const ExampleEvent.started()),
          ),
          ExampleLoaded(:final items) when items.isEmpty => EmptyView(
            message: context.l10n.exampleEmpty,
          ),
          ExampleLoaded(:final items) => RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => ExampleItemTile(item: items[i]),
            ),
          ),
        },
      ),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<ExampleBloc>()
      ..add(const ExampleEvent.refreshed());
    await bloc.stream.first;
  }
}

/// Rebuilds only when the item count changes ([BlocSelector]).
class _ItemCount extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ExampleBloc, ExampleState, int?>(
      selector: (state) => switch (state) {
        ExampleLoaded(:final items) => items.length,
        _ => null,
      },
      builder: (context, count) => SizedBox(
        height: 24,
        child: count == null
            ? null
            : Text(
                context.l10n.exampleItemCount(count),
                key: const Key('example_item_count'),
              ),
      ),
    );
  }
}
