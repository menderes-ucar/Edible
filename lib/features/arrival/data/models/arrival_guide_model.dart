import '../../domain/entities/arrival_guide.dart';

class ArrivalGuideModel extends ArrivalGuide {
  const ArrivalGuideModel({
    required super.countryCode,
    required super.countryName,
    required super.cityName,
    required super.currencyCode,
    required super.emergencyNumber,
    required super.airportTransfer,
    required super.taxiTip,
    required super.simTip,
    required super.tippingTip,
    required super.firstDayChecklist,
    required super.scamWarnings,
    required super.mustTryTitles,
    required super.basicPhrases,
  });

  factory ArrivalGuideModel.fromMap(Map<String, dynamic> map) {
    return ArrivalGuideModel(
      countryCode: (map['country_code'] ?? '').toString(),
      countryName: (map['country_name'] ?? '').toString(),
      cityName: (map['city_name'] ?? '').toString(),
      currencyCode: (map['currency_code'] ?? '').toString(),
      emergencyNumber: (map['emergency_number'] ?? '').toString(),
      airportTransfer: (map['airport_transfer'] ?? '').toString(),
      taxiTip: (map['taxi_tip'] ?? '').toString(),
      simTip: (map['sim_tip'] ?? '').toString(),
      tippingTip: (map['tipping_tip'] ?? '').toString(),
      firstDayChecklist: _stringList(map['first_day_checklist']),
      scamWarnings: _stringList(map['scam_warnings']),
      mustTryTitles: _stringList(map['must_try_titles']),
      basicPhrases: ((map['basic_phrases'] as List?) ?? const [])
          .map((item) {
            final value = Map<String, dynamic>.from(item as Map);
            return ArrivalPhrase(
              local: (value['local'] ?? '').toString(),
              pronunciation: (value['pronunciation'] ?? '').toString(),
              translation: (value['translation'] ?? '').toString(),
            );
          })
          .toList(growable: false),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList(growable: false);
  }
}
