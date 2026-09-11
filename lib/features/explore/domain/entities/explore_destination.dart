import 'explore_content.dart';

class ExploreDestination {
  const ExploreDestination({
    required this.countryCode,
    required this.countryName,
    required this.cityName,
    required this.latitude,
    required this.longitude,
    required this.contents,
  });

  final String countryCode;
  final String countryName;
  final String cityName;
  final double latitude;
  final double longitude;
  final List<ExploreContent> contents;

  List<ExploreContent> get featured =>
      contents.where((item) => item.isFeatured).toList(growable: false);

  List<ExploreContent> get mustTry => contents
      .where(
        (item) =>
            item.category.name == 'food' ||
            item.category.name == 'snack' ||
            item.category.name == 'fruit' ||
            item.category.name == 'drink',
      )
      .toList(growable: false);

  List<ExploreContent> get culture => contents
      .where((item) => item.category.name == 'culture')
      .toList(growable: false);
}
