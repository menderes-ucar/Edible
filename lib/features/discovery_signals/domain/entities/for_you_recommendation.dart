import '../../../explore/domain/entities/explore_content.dart';

class ForYouRecommendation {
  const ForYouRecommendation({
    required this.content,
    required this.score,
    required this.reason,
  });

  final ExploreContent content;
  final double score;
  final ForYouReason reason;
}

enum ForYouReason {
  categoryAffinity,
  featuredFallback,
  freshFallback,
}
