
class CityReleasePolicy {
  const CityReleasePolicy._();

  static const minimumPlaces = 5;
  static const minimumCategories = 5;

  static bool isReleaseReady({
    required int placeCount,
    required int categoryCount,
    required int placeholderCount,
    required int exactCoordinateCount,
    required int verifiedMediaCount,
  }) {
    return placeCount >= minimumPlaces &&
        categoryCount >= minimumCategories &&
        placeholderCount == 0 &&
        exactCoordinateCount >= placeCount &&
        verifiedMediaCount >= placeCount;
  }
}
