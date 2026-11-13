import 'package:flutter/material.dart';

/// Primary call-to-action button with an optional loading state.
class AppButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);
    final onTap = isLoading ? null : onPressed;
    if (icon != null && !isLoading) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: child,
      );
    }
    return FilledButton(onPressed: onTap, child: child);
  }
}
