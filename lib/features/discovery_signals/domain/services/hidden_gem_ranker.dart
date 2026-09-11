import '../../../explore/domain/entities/explore_content.dart';
import '../entities/content_exposure.dart';
import '../entities/discovery_affinity.dart';
import '../entities/hidden_gem_recommendation.dart';

class HiddenGemRanker {
  const HiddenGemRanker();

  List<HiddenGemRecommendation> rank({
    required List<ExploreContent> contents,
    required List<DiscoveryAffinity> affinities,
    required List<ContentExposure> exposure,
    int limit = 12,
  }) {
    if (contents.isEmpty || limit <= 0) return const [];

    final affinityByCategory = <String, double>{
      for (final affinity in affinities)
        affinity.category.trim().toLowerCase(): affinity.signalScore,
    };
    final exposureByContent = <String, ContentExposure>{
      for (final item in exposure) item.contentId: item,
    };

    final maxAffinity = affinityByCategory.values.fold<double>(
      0,
      (current, value) => value > current ? value : current,
    );

    final ranked = contents.map((content) {
      final exposureItem = exposureByContent[content.id];
      final interactions = exposureItem?.interactionCount ?? 0;
      final users = exposureItem?.uniqueUsers ?? 0;

      // Novelty decreases smoothly as exposure grows. It never becomes
      // negative and does not require a catalog-specific popularity column.
      final novelty = 1 / (1 + (interactions / 8));

      final rawAffinity =
          affinityByCategory[content.category.name.toLowerCase()] ?? 0;
      final affinity =
          maxAffinity <= 0 ? 0 : (rawAffinity / maxAffinity).clamp(0, 1);

      // Featured is useful as a quality prior for For You, but Hidden Gems
      // should not simply mirror editorial/popular content.
      final nonFeaturedBonus = content.isFeatured ? 0.0 : 0.12;

      // Unique-user exposure prevents one enthusiastic user from making an
      // otherwise unknown place look globally popular.
      final audienceNovelty = 1 / (1 + (users / 4));

      final score =
          (novelty * 0.48) +
          (audienceNovelty * 0.22) +
          (affinity * 0.18) +
          nonFeaturedBonus;

      final reason = affinity >= 0.45
          ? HiddenGemReason.matchesInterest
          : interactions <= 3
              ? HiddenGemReason.lowExposure
              : HiddenGemReason.localDiscovery;

      return HiddenGemRecommendation(
        content: content,
        score: score,
        reason: reason,
        interactionCount: interactions,
      );
    }).toList();

    ranked.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      final exposureCompare = a.interactionCount.compareTo(b.interactionCount);
      if (exposureCompare != 0) return exposureCompare;
      return a.content.title.toLowerCase().compareTo(
            b.content.title.toLowerCase(),
          );
    });

    return ranked.take(limit).toList(growable: false);
  }
}
