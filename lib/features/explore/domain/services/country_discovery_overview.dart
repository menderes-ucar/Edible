import '../entities/explore_category.dart';
import '../entities/explore_content.dart';

class CountryCityOverview {
  const CountryCityOverview({
    required this.cityName,
    required this.discoveryCount,
    required this.featuredCount,
    required this.imageUrl,
  });

  final String cityName;
  final int discoveryCount;
  final int featuredCount;
  final String? imageUrl;
}

class CountryDiscoveryOverview {
  const CountryDiscoveryOverview({
    required this.totalCount,
    required this.featuredCount,
    required this.cityCount,
    required this.categoryCounts,
    required this.cities,
  });

  final int totalCount;
  final int featuredCount;
  final int cityCount;
  final Map<ExploreCategory, int> categoryCounts;
  final List<CountryCityOverview> cities;

  int countFor(ExploreCategory category) => categoryCounts[category] ?? 0;
}

class CountryDiscoveryOverviewBuilder {
  const CountryDiscoveryOverviewBuilder._();

  static CountryDiscoveryOverview build(Iterable<ExploreContent> contents) {
    final unique = <String, ExploreContent>{};
    for (final item in contents) {
      unique.putIfAbsent(item.id, () => item);
    }

    final categoryCounts = <ExploreCategory, int>{};
    final cityItems = <String, List<ExploreContent>>{};
    var featuredCount = 0;

    for (final item in unique.values) {
      categoryCounts[item.category] = (categoryCounts[item.category] ?? 0) + 1;
      cityItems.putIfAbsent(item.cityName, () => <ExploreContent>[]).add(item);
      if (item.isFeatured) featuredCount++;
    }

    final cities = cityItems.entries.map((entry) {
      final values = entry.value;
      String? imageUrl;
      for (final item in values) {
        if (item.coverImageUrl?.trim().isNotEmpty == true) {
          imageUrl = item.coverImageUrl!.trim();
          break;
        }
      }
      return CountryCityOverview(
        cityName: entry.key,
        discoveryCount: values.length,
        featuredCount: values.where((item) => item.isFeatured).length,
        imageUrl: imageUrl,
      );
    }).toList(growable: false)
      ..sort((a, b) {
        final featured = b.featuredCount.compareTo(a.featuredCount);
        if (featured != 0) return featured;
        final count = b.discoveryCount.compareTo(a.discoveryCount);
        if (count != 0) return count;
        return a.cityName.toLowerCase().compareTo(b.cityName.toLowerCase());
      });

    return CountryDiscoveryOverview(
      totalCount: unique.length,
      featuredCount: featuredCount,
      cityCount: cities.length,
      categoryCounts: Map<ExploreCategory, int>.unmodifiable(categoryCounts),
      cities: List<CountryCityOverview>.unmodifiable(cities),
    );
  }
}
