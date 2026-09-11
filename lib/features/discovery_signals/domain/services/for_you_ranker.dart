import '../../../explore/domain/entities/explore_content.dart';
import '../entities/discovery_affinity.dart';
import '../entities/for_you_recommendation.dart';
import 'recommendation_diversifier.dart';

class ForYouRanker {
  const ForYouRanker({RecommendationDiversifier diversifier = const RecommendationDiversifier()}) : _diversifier = diversifier;
  final RecommendationDiversifier _diversifier;

  List<ForYouRecommendation> rank({
    required List<ExploreContent> contents,
    required List<DiscoveryAffinity> affinities,
    int limit = 12,
  }) {
    if (contents.isEmpty || limit <= 0) return const [];

    final affinityByCategory = <String, double>{
      for (final affinity in affinities)
        affinity.category.trim().toLowerCase(): affinity.signalScore,
    };

    final scored = contents.map((content) {
      final categoryKey = content.category.name.toLowerCase();
      final affinity = affinityByCategory[categoryKey] ?? 0;

      // Phase 47 deliberately keeps ranking explainable and deterministic.
      // Behavior affinity is the dominant signal. Featured is a small quality
      // prior, never strong enough to erase real user preference.
      final score = (affinity * 10) + (content.isFeatured ? 2.5 : 0);

      final reason = affinity > 0
          ? ForYouReason.categoryAffinity
          : content.isFeatured
              ? ForYouReason.featuredFallback
              : ForYouReason.freshFallback;

      return ForYouRecommendation(
        content: content,
        score: score,
        reason: reason,
      );
    }).toList();

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;

      final featured = (b.content.isFeatured ? 1 : 0).compareTo(
        a.content.isFeatured ? 1 : 0,
      );
      if (featured != 0) return featured;

      return a.content.title.toLowerCase().compareTo(
            b.content.title.toLowerCase(),
          );
    });

    return _diversifier.diversify(scored, limit: limit);
  }
}
