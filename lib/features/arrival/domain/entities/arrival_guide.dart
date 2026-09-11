class ArrivalGuide {
  const ArrivalGuide({
    required this.countryCode,
    required this.countryName,
    required this.cityName,
    required this.currencyCode,
    required this.emergencyNumber,
    required this.airportTransfer,
    required this.taxiTip,
    required this.simTip,
    required this.tippingTip,
    required this.firstDayChecklist,
    required this.scamWarnings,
    required this.mustTryTitles,
    required this.basicPhrases,
  });

  final String countryCode;
  final String countryName;
  final String cityName;

  final String currencyCode;
  final String emergencyNumber;

  final String airportTransfer;
  final String taxiTip;
  final String simTip;
  final String tippingTip;

  final List<String> firstDayChecklist;
  final List<String> scamWarnings;
  final List<String> mustTryTitles;
  final List<ArrivalPhrase> basicPhrases;

  bool get isEmpty =>
      airportTransfer.trim().isEmpty &&
      taxiTip.trim().isEmpty &&
      simTip.trim().isEmpty &&
      tippingTip.trim().isEmpty &&
      firstDayChecklist.isEmpty &&
      scamWarnings.isEmpty &&
      mustTryTitles.isEmpty &&
      basicPhrases.isEmpty;
}

class ArrivalPhrase {
  const ArrivalPhrase({
    required this.local,
    required this.pronunciation,
    required this.translation,
  });

  final String local;
  final String pronunciation;
  final String translation;
}
