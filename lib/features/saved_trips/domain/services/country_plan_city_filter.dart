import '../../../explore/domain/entities/explore_content.dart';

class CountryPlanCityFilter {
  const CountryPlanCityFilter._();

  static List<ExploreContent> apply({
    required Iterable<ExploreContent> contents,
    required String? cityName,
  }) {
    final target = cityName?.trim().toLowerCase() ?? '';
    if (target.isEmpty) return List<ExploreContent>.unmodifiable(contents);

    return List<ExploreContent>.unmodifiable(
      contents.where(
        (item) => item.cityName.trim().toLowerCase() == target,
      ),
    );
  }
}
