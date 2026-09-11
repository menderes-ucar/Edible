enum TravelBadgeTier {
  bronze,
  silver,
  gold,
}

class TravelBadge {
  const TravelBadge({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.iconName,
    required this.tier,
    required this.unlocked,
    required this.current,
    required this.target,
  });

  final String id;
  final String titleKey;
  final String descriptionKey;
  final String iconName;
  final TravelBadgeTier tier;
  final bool unlocked;
  final int current;
  final int target;

  double get progress {
    if (target <= 0) return unlocked ? 1 : 0;
    return (current / target).clamp(0, 1);
  }
}
