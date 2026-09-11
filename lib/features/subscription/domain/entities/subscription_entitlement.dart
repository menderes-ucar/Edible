enum SubscriptionPlan {
  free,
  premium;

  static SubscriptionPlan fromValue(String? value) {
    return switch ((value ?? '').trim().toLowerCase()) {
      'premium' => SubscriptionPlan.premium,
      _ => SubscriptionPlan.free,
    };
  }
}

enum PremiumFeature {
  offlineCityPacks,
  advancedTripPlanner,
  travelAssistant,
}

class SubscriptionEntitlement {
  const SubscriptionEntitlement({
    required this.plan,
    required this.isActive,
    this.expiresAt,
  });

  final SubscriptionPlan plan;
  final bool isActive;
  final DateTime? expiresAt;

  bool get isPremium =>
      plan == SubscriptionPlan.premium &&
      isActive &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  bool canUse(PremiumFeature feature) {
    if (isPremium) return true;

    return switch (feature) {
      PremiumFeature.offlineCityPacks => false,
      PremiumFeature.advancedTripPlanner => false,
      PremiumFeature.travelAssistant => false,
    };
  }

  static const free = SubscriptionEntitlement(
    plan: SubscriptionPlan.free,
    isActive: true,
  );
}
