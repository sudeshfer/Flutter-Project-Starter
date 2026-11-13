import 'package:app_core/core/config/app_config.dart';
import 'package:app_core/core/l10n/gen/app_localizations.dart';
import 'package:app_core/core/theme/app_theme.dart';
import 'package:app_core/shared/widgets/flavor_banner.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Root widget. Dependencies come in through the constructor.
class App extends StatelessWidget {
  const new({required this.config, required this.router, super.key});

  final AppConfig config;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => FlavorBanner(
        flavor: config.flavor,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
