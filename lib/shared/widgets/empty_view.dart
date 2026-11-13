import 'package:app_core/core/extensions/context_extensions.dart';
import 'package:app_core/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Full-screen empty state.
class EmptyView extends StatelessWidget {
  const new({
    required this.message,
    this.icon = Icons.inbox_outlined,
    super.key,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppSpacing.xxl,
              color: context.colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
