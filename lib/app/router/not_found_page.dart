import 'package:app_core/app/router/route_names.dart';
import 'package:app_core/core/extensions/context_extensions.dart';
import 'package:app_core/core/theme/app_spacing.dart';
import 'package:app_core/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 404 / router error page.
class NotFoundPage extends StatelessWidget {
  const new({required this.location, super.key});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.notFoundTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.notFoundMessage(location),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: context.l10n.goHome,
                onPressed: () => context.goNamed(RouteNames.example),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
