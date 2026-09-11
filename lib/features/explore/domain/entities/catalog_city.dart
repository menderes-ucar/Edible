
class CatalogCity {
  const CatalogCity({
    required this.id,
    required this.countryCode,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.population,
    this.nativeName,
  });

  final String id;
  final String countryCode;
  final String displayName;
  final String? nativeName;
  final double latitude;
  final double longitude;
  final int? population;
}
