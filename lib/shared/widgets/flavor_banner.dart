import 'package:app_core/core/config/flavor.dart';
import 'package:app_core/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Corner ribbon (DEV / QA / STG / UAT) shown in every non-prod flavor.
class FlavorBanner extends StatelessWidget {
  const new({required this.flavor, required this.child, super.key});

  final Flavor flavor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (flavor.isProd) return child;
    return Banner(
      message: flavor.label,
      location: BannerLocation.topEnd,
      color: switch (flavor) {
        Flavor.dev => AppColors.bannerDev,
        Flavor.qa => AppColors.bannerQa,
        Flavor.staging || Flavor.prod => AppColors.bannerStaging,
        Flavor.uat => AppColors.bannerUat,
      },
      child: child,
    );
  }
}
