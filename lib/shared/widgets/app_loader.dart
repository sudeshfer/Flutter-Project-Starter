import 'package:flutter/material.dart';

/// Centered progress indicator for full-screen loading states.
class AppLoader extends StatelessWidget {
  const new({this.semanticsLabel, super.key});

  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) =>
      Center(child: CircularProgressIndicator(semanticsLabel: semanticsLabel));
}
