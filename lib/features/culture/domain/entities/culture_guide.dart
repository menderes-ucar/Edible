enum CultureTipType {
  doTip,
  dontTip,
  tipping,
  transport,
  religiousPlace,
  touristMistake,
  safety,
  scam,
  phrase;

  static CultureTipType fromValue(String value) {
    return CultureTipType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => CultureTipType.doTip,
    );
  }
}

class CultureGuideItem {
  const CultureGuideItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.priority,
    this.phraseLocal,
    this.phrasePronunciation,
    this.phraseTranslation,
  });

  final String id;
  final CultureTipType type;
  final String title;
  final String body;
  final int priority;

  final String? phraseLocal;
  final String? phrasePronunciation;
  final String? phraseTranslation;

  bool get isPhrase => type == CultureTipType.phrase;
}

class CultureGuide {
  const CultureGuide({
    required this.countryCode,
    required this.countryName,
    required this.cityName,
    required this.items,
  });

  final String countryCode;
  final String countryName;
  final String cityName;
  final List<CultureGuideItem> items;

  List<CultureGuideItem> ofType(CultureTipType type) =>
      items.where((item) => item.type == type).toList(growable: false);

  bool get isEmpty => items.isEmpty;
}
