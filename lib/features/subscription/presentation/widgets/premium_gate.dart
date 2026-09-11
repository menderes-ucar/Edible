import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../domain/entities/subscription_entitlement.dart';
import '../providers/subscription_provider.dart';

class PremiumGate {
  const PremiumGate._();

  static bool allowOrOpenPaywall(
    BuildContext context,
    PremiumFeature feature,
  ) {
    final subscription = context.read<SubscriptionProvider>();

    if (subscription.canUse(feature)) return true;

    context.push(
      '${AppRoutes.paywall}?feature=${feature.name}',
    );
    return false;
  }
}
