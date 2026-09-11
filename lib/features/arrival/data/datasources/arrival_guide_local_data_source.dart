import '../../domain/entities/arrival_guide.dart';

class ArrivalGuideLocalDataSource {
  const ArrivalGuideLocalDataSource();

  ArrivalGuide getGuide({
    required String countryCode,
    required String cityName,
  }) {
    return switch (countryCode.toUpperCase()) {
      'TR' => _istanbul(cityName),
      'JP' => _tokyo(cityName),
      'IT' => _rome(cityName),
      _ => ArrivalGuide(
          countryCode: countryCode,
          countryName: countryCode,
          cityName: cityName,
          currencyCode: '',
          emergencyNumber: '',
          airportTransfer: '',
          taxiTip: '',
          simTip: '',
          tippingTip: '',
          firstDayChecklist: const [],
          scamWarnings: const [],
          mustTryTitles: const [],
          basicPhrases: const [],
        ),
    };
  }

  ArrivalGuide _istanbul(String cityName) => ArrivalGuide(
        countryCode: 'TR',
        countryName: 'Türkiye',
        cityName: cityName,
        currencyCode: 'TRY',
        emergencyNumber: '112',
        airportTransfer:
            'Check the official airport transport desks and current rail/bus options before leaving the terminal.',
        taxiTip:
            'Use licensed taxis or reputable ride apps and make sure the meter or agreed fare is clear before departure.',
        simTip:
            'Compare tourist SIM/eSIM options before purchase and keep your passport available if registration is required.',
        tippingTip:
            'Small tips are common when service is good, but always check whether a service charge is already included.',
        firstDayChecklist: const [
          'Get local currency or a reliable card payment option ready.',
          'Save your accommodation address offline.',
          'Check public transport card and airport connection options.',
          'Learn the emergency number 112.',
          'Save at least two basic Turkish phrases.',
        ],
        scamWarnings: const [
          'Avoid unofficial taxi solicitors inside or around transport hubs.',
          'Be cautious with unsolicited offers that quickly turn into requests for payment.',
        ],
        mustTryTitles: const [
          'Simit',
          'Turkish coffee',
          'Baklava',
        ],
        basicPhrases: const [
          ArrivalPhrase(
            local: 'Merhaba',
            pronunciation: 'mehr-hah-bah',
            translation: 'Hello',
          ),
          ArrivalPhrase(
            local: 'Teşekkür ederim',
            pronunciation: 'teh-shek-kur eh-deh-rim',
            translation: 'Thank you',
          ),
        ],
      );

  ArrivalGuide _tokyo(String cityName) => ArrivalGuide(
        countryCode: 'JP',
        countryName: 'Japan',
        cityName: cityName,
        currencyCode: 'JPY',
        emergencyNumber: '110 / 119',
        airportTransfer:
            'Compare official rail, airport bus, and taxi options based on your destination before leaving the terminal.',
        taxiTip:
            'Official taxis are metered; tipping is generally not expected.',
        simTip:
            'Data-only eSIMs and tourist SIMs are common options for short stays.',
        tippingTip:
            'Tipping is generally not expected in everyday restaurants and taxis.',
        firstDayChecklist: const [
          'Set up a transport/payment card option.',
          'Save your hotel address in Japanese if possible.',
          'Learn basic train etiquette.',
          'Keep phone calls quiet on public transport.',
          'Try one local convenience-store or neighborhood food stop.',
        ],
        scamWarnings: const [
          'Be cautious with persistent nightlife touts in entertainment districts.',
          'Check menu prices before entering unfamiliar bars or clubs.',
        ],
        mustTryTitles: const [
          'Ramen',
          'Sushi',
          'Melon pan',
        ],
        basicPhrases: const [
          ArrivalPhrase(
            local: 'これをください',
            pronunciation: 'Kore o kudasai',
            translation: 'This one, please.',
          ),
          ArrivalPhrase(
            local: 'ありがとうございます',
            pronunciation: 'Arigatou gozaimasu',
            translation: 'Thank you very much.',
          ),
        ],
      );

  ArrivalGuide _rome(String cityName) => ArrivalGuide(
        countryCode: 'IT',
        countryName: 'Italy',
        cityName: cityName,
        currencyCode: 'EUR',
        emergencyNumber: '112',
        airportTransfer:
            'Use official airport rail, bus, or licensed taxi services and compare the destination before choosing.',
        taxiTip:
            'Use licensed taxis from official ranks and confirm any fixed airport fare rules before departure.',
        simTip:
            'Compare EU roaming, local SIM, and eSIM options based on your current mobile plan.',
        tippingTip:
            'Tipping is optional; check whether service or cover charges are already on the bill.',
        firstDayChecklist: const [
          'Validate local transport tickets when required.',
          'Keep valuables secure in crowded areas.',
          'Save your accommodation and emergency contacts offline.',
          'Check dress expectations before major church visits.',
          'Try a local espresso or Roman street food stop.',
        ],
        scamWarnings: const [
          'Be cautious with aggressive bracelet or gift offers.',
          'Watch belongings around crowded transport and major tourist sights.',
        ],
        mustTryTitles: const [
          'Supplì',
          'Carbonara',
          'Espresso',
        ],
        basicPhrases: const [
          ArrivalPhrase(
            local: 'Buongiorno',
            pronunciation: 'bwon-JOR-no',
            translation: 'Hello / good morning',
          ),
          ArrivalPhrase(
            local: 'Grazie',
            pronunciation: 'GRA-tsyeh',
            translation: 'Thank you',
          ),
        ],
      );
}
