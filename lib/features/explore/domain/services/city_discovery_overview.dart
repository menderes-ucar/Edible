import '../entities/explore_category.dart';
import '../entities/explore_content.dart';

class CityDiscoveryOverview {
  const CityDiscoveryOverview({
    required this.totalCount,
    required this.featuredCount,
    required this.categoryCounts,
  });

  final int totalCount;
  final int featuredCount;
  final Map<ExploreCategory, int> categoryCounts;

  int countFor(ExploreCategory category) => categoryCounts[category] ?? 0;
}

class CityDiscoveryOverviewBuilder {
  const CityDiscoveryOverviewBuilder._();

  static CityDiscoveryOverview build(Iterable<ExploreContent> contents) {
    final ids = <String>{};
    var featured = 0;
    final counts = <ExploreCategory, int>{};

    for (final item in contents) {
      if (!ids.add(item.id)) continue;
      counts[item.category] = (counts[item.category] ?? 0) + 1;
      if (item.isFeatured) featured++;
    }

    return CityDiscoveryOverview(
      totalCount: ids.length,
      featuredCount: featured,
      categoryCounts: Map<ExploreCategory, int>.unmodifiable(counts),
    );
  }
}
