
class LocationDisplayNameService {
  const LocationDisplayNameService();

  String countryName({
    required String locale,
    required String countryCode,
    required String fallbackName,
    Map<String, String> translations = const {},
    String? nativeName,
  }) {
    final normalized = _locale(locale);
    return _firstNonBlank([
      translations[normalized],
      translations['en'],
      _latinFriendly(fallbackName),
      nativeName,
      countryCode.toUpperCase(),
    ]);
  }

  String cityName({
    required String locale,
    required String fallbackName,
    String? asciiName,
    String? nativeName,
    Map<String, String> translations = const {},
  }) {
    final normalized = _locale(locale);
    return _firstNonBlank([
      translations[normalized],
      normalized == 'en' ? asciiName : null,
      _latinFriendly(fallbackName),
      asciiName,
      nativeName,
    ]);
  }

  String _locale(String value) =>
      value.trim().toLowerCase().split(RegExp('[-_]')).first;

  String? _latinFriendly(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final hasLatin = RegExp(r'[A-Za-zÀ-ž]').hasMatch(value);
    return hasLatin ? value.trim() : null;
  }

  String _firstNonBlank(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }
}
