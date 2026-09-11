enum DiscoveryEventType {
  contentOpen('content_open'),
  categorySelect('category_select'),
  searchSelect('search_select'),
  recommendationUseful('recommendation_useful'),
  recommendationNotForMe('recommendation_not_for_me');

  const DiscoveryEventType(this.wireValue);
  final String wireValue;
}

class DiscoveryEvent {
  const DiscoveryEvent({
    required this.type,
    this.contentId,
    this.category,
    this.countryCode,
    this.cityName,
    this.query,
  });

  final DiscoveryEventType type;
  final String? contentId;
  final String? category;
  final String? countryCode;
  final String? cityName;
  final String? query;
}
