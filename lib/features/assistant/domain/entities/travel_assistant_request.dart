class TravelAssistantRequest {
  const TravelAssistantRequest({
    required this.message,
    required this.languageCode,
    this.defaultCityName,
  });

  final String message;
  final String languageCode;
  final String? defaultCityName;
}
