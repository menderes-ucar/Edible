import '../../../explore/domain/entities/explore_content.dart';

class HiddenGemRecommendation {
  const HiddenGemRecommendation({
    required this.content,
    required this.score,
    required this.reason,
    required this.interactionCount,
  });

  final ExploreContent content;
  final double score;
  final HiddenGemReason reason;
  final int interactionCount;
}

enum HiddenGemReason {
  matchesInterest,
  lowExposure,
  localDiscovery,
}
