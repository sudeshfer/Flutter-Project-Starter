import 'package:app_core/core/extensions/context_extensions.dart';
import 'package:app_core/core/theme/app_spacing.dart';
import 'package:app_core/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// Full-screen error state with an optional retry action.
class ErrorView extends StatelessWidget {
  const new({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: AppSpacing.xxl,
              color: context.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(context.l10n.errorTitle, style: context.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: context.l10n.retry,
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
