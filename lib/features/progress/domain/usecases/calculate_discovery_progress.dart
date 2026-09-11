import '../../../explore/domain/entities/explore_content.dart';
import '../entities/discovery_stats.dart';
import '../entities/travel_badge.dart';

class CalculateDiscoveryProgress {
  const CalculateDiscoveryProgress();

  DiscoveryStats forContents({
    required Iterable<ExploreContent> contents,
    required Set<String> visitedIds,
    required Set<String> triedIds,
  }) {
    final items = contents.toList(growable: false);
    final ids = items.map((item) => item.id).toSet();

    final visited = visitedIds.intersection(ids);
    final tried = triedIds.intersection(ids);
    final completed = {...visited, ...tried};

    return DiscoveryStats(
      total: ids.length,
      completed: completed.length,
      visited: visited.length,
      tried: tried.length,
    );
  }

  List<TravelBadge> badges({
    required Iterable<ExploreContent> allContents,
    required Set<String> visitedIds,
    required Set<String> triedIds,
  }) {
    final contents = allContents.toList(growable: false);

    final visitedContents = contents
        .where((item) => visitedIds.contains(item.id))
        .toList(growable: false);

    final triedContents = contents
        .where((item) => triedIds.contains(item.id))
        .toList(growable: false);

    final visitedCountries =
        visitedContents.map((item) => item.countryCode).toSet().length;
    final visitedCities =
        visitedContents.map((item) => '${item.countryCode}/${item.cityName}').toSet().length;

    final foodsTried = triedContents.where((item) {
      final category = item.category.name;
      return category == 'food' ||
          category == 'snack' ||
          category == 'fruit' ||
          category == 'drink';
    }).length;

    final cultureVisited = visitedContents
        .where((item) => item.category.name == 'culture')
        .length;

    return [
      _badge(
        id: 'first_step',
        titleKey: 'badgeFirstStep',
        descriptionKey: 'badgeFirstStepDesc',
        iconName: 'footprint',
        current: visitedContents.length,
        target: 1,
        tier: TravelBadgeTier.bronze,
      ),
      _badge(
        id: 'city_explorer',
        titleKey: 'badgeCityExplorer',
        descriptionKey: 'badgeCityExplorerDesc',
        iconName: 'city',
        current: visitedCities,
        target: 3,
        tier: TravelBadgeTier.bronze,
      ),
      _badge(
        id: 'world_explorer',
        titleKey: 'badgeWorldExplorer',
        descriptionKey: 'badgeWorldExplorerDesc',
        iconName: 'world',
        current: visitedCountries,
        target: 5,
        tier: TravelBadgeTier.silver,
      ),
      _badge(
        id: 'food_explorer',
        titleKey: 'badgeFoodExplorer',
        descriptionKey: 'badgeFoodExplorerDesc',
        iconName: 'food',
        current: foodsTried,
        target: 10,
        tier: TravelBadgeTier.silver,
      ),
      _badge(
        id: 'culture_seeker',
        titleKey: 'badgeCultureSeeker',
        descriptionKey: 'badgeCultureSeekerDesc',
        iconName: 'culture',
        current: cultureVisited,
        target: 10,
        tier: TravelBadgeTier.gold,
      ),
      _badge(
        id: 'global_taster',
        titleKey: 'badgeGlobalTaster',
        descriptionKey: 'badgeGlobalTasterDesc',
        iconName: 'restaurant',
        current: triedContents.length,
        target: 25,
        tier: TravelBadgeTier.gold,
      ),
    ];
  }

  TravelBadge _badge({
    required String id,
    required String titleKey,
    required String descriptionKey,
    required String iconName,
    required int current,
    required int target,
    required TravelBadgeTier tier,
  }) {
    return TravelBadge(
      id: id,
      titleKey: titleKey,
      descriptionKey: descriptionKey,
      iconName: iconName,
      tier: tier,
      unlocked: current >= target,
      current: current,
      target: target,
    );
  }
}
