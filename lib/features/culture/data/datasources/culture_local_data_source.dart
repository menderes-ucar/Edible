import '../../domain/entities/culture_guide.dart';
import '../models/culture_guide_item_model.dart';

class CultureLocalDataSource {
  const CultureLocalDataSource();
  CultureGuide getGuide({required String countryCode, required String cityName}) {
    final code = countryCode.toUpperCase();
    final items = switch (code) { 'TR' => _istanbul, 'JP' => _tokyo, 'IT' => _rome, _ => const <CultureGuideItemModel>[] };
    return CultureGuide(countryCode: code, countryName: switch (code) { 'TR' => 'Türkiye', 'JP' => 'Japan', 'IT' => 'Italy', _ => code }, cityName: cityName, items: items);
  }
}

const _istanbul = <CultureGuideItemModel>[
  CultureGuideItemModel(id: 'culture-tr-01', type: CultureTipType.doTip, title: 'Respect religious spaces', body: 'Dress modestly and follow posted guidance when visiting mosques.', priority: 10),
  CultureGuideItemModel(id: 'culture-tr-02', type: CultureTipType.dontTip, title: 'Do not block prayer areas', body: 'Avoid standing in active prayer rows or disturbing worshippers.', priority: 9),
  CultureGuideItemModel(id: 'culture-tr-03', type: CultureTipType.tipping, title: 'Tipping', body: 'A small tip is appreciated in restaurants when service is good.', priority: 8),
  CultureGuideItemModel(id: 'culture-tr-04', type: CultureTipType.transport, title: 'Public transport', body: 'Offer priority seats and let passengers exit before boarding.', priority: 8),
  CultureGuideItemModel(id: 'culture-tr-05', type: CultureTipType.religiousPlace, title: 'Mosque visits', body: 'Remove shoes where required and keep voices low.', priority: 9),
  CultureGuideItemModel(id: 'culture-tr-06', type: CultureTipType.touristMistake, title: 'Rush-hour ferries', body: 'Allow extra time around commuter peaks and crowded piers.', priority: 6),
  CultureGuideItemModel(id: 'culture-tr-07', type: CultureTipType.safety, title: 'Crowded areas', body: 'Keep valuables secure around busy transport hubs and tourist streets.', priority: 10),
  CultureGuideItemModel(id: 'culture-tr-08', type: CultureTipType.scam, title: 'Taxi pricing', body: 'Prefer licensed taxis and verify that the meter is running.', priority: 10),
  CultureGuideItemModel(id: 'culture-tr-09', type: CultureTipType.scam, title: 'Unsolicited invitations', body: 'Be cautious with persistent invitations that quickly become expensive.', priority: 8),
  CultureGuideItemModel(id: 'culture-tr-10', type: CultureTipType.phrase, title: 'Hello', body: 'A simple greeting works in most situations.', priority: 5, phraseLocal: 'Merhaba', phrasePronunciation: 'mehr-hah-bah', phraseTranslation: 'Hello'),
  CultureGuideItemModel(id: 'culture-tr-11', type: CultureTipType.phrase, title: 'Thank you', body: 'Useful everywhere.', priority: 5, phraseLocal: 'Teşekkür ederim', phrasePronunciation: 'teh-shek-kur eh-deh-rim', phraseTranslation: 'Thank you'),
  CultureGuideItemModel(id: 'culture-tr-12', type: CultureTipType.phrase, title: 'How much?', body: 'Useful in markets and shops.', priority: 5, phraseLocal: 'Ne kadar?', phrasePronunciation: 'neh kah-dahr', phraseTranslation: 'How much?'),
];

const _tokyo = <CultureGuideItemModel>[
  CultureGuideItemModel(id: 'culture-jp-01', type: CultureTipType.doTip, title: 'Queue in order', body: 'Follow platform markings and wait in line for trains and shops.', priority: 10),
  CultureGuideItemModel(id: 'culture-jp-02', type: CultureTipType.dontTip, title: 'Keep calls quiet', body: 'Avoid loud phone calls on trains and other shared spaces.', priority: 10),
  CultureGuideItemModel(id: 'culture-jp-03', type: CultureTipType.tipping, title: 'Tipping', body: 'Tipping is generally not expected in everyday restaurants.', priority: 9),
  CultureGuideItemModel(id: 'culture-jp-04', type: CultureTipType.transport, title: 'Train etiquette', body: 'Let passengers exit first and keep bags from blocking aisles.', priority: 10),
  CultureGuideItemModel(id: 'culture-jp-05', type: CultureTipType.religiousPlace, title: 'Temple and shrine etiquette', body: 'Observe signs, keep voices low, and avoid interrupting worship.', priority: 9),
  CultureGuideItemModel(id: 'culture-jp-06', type: CultureTipType.touristMistake, title: 'Eating while walking', body: 'In many areas it is better to finish food near where you bought it.', priority: 7),
  CultureGuideItemModel(id: 'culture-jp-07', type: CultureTipType.safety, title: 'Last train planning', body: 'Check your last train before a late evening out.', priority: 7),
  CultureGuideItemModel(id: 'culture-jp-08', type: CultureTipType.scam, title: 'Nightlife touts', body: 'Be cautious with persistent touts in nightlife districts.', priority: 9),
  CultureGuideItemModel(id: 'culture-jp-09', type: CultureTipType.doTip, title: 'Cash tray etiquette', body: 'Use the payment tray when a shop provides one.', priority: 6),
  CultureGuideItemModel(id: 'culture-jp-10', type: CultureTipType.phrase, title: 'This one, please', body: 'Useful when ordering.', priority: 5, phraseLocal: 'これをください', phrasePronunciation: 'Kore o kudasai', phraseTranslation: 'This one, please.'),
  CultureGuideItemModel(id: 'culture-jp-11', type: CultureTipType.phrase, title: 'Thank you very much', body: 'Polite and widely useful.', priority: 5, phraseLocal: 'ありがとうございます', phrasePronunciation: 'Arigatou gozaimasu', phraseTranslation: 'Thank you very much.'),
  CultureGuideItemModel(id: 'culture-jp-12', type: CultureTipType.phrase, title: 'Excuse me', body: 'Useful for getting attention politely.', priority: 5, phraseLocal: 'すみません', phrasePronunciation: 'Sumimasen', phraseTranslation: 'Excuse me / sorry.'),
];

const _rome = <CultureGuideItemModel>[
  CultureGuideItemModel(id: 'culture-it-01', type: CultureTipType.doTip, title: 'Respect church dress codes', body: 'Some churches expect shoulders and knees to be covered.', priority: 9),
  CultureGuideItemModel(id: 'culture-it-02', type: CultureTipType.dontTip, title: 'Do not sit on protected monuments', body: 'Follow local signs around historic monuments and fountains.', priority: 8),
  CultureGuideItemModel(id: 'culture-it-03', type: CultureTipType.tipping, title: 'Tipping', body: 'Tipping is optional; service charges may already be included.', priority: 8),
  CultureGuideItemModel(id: 'culture-it-04', type: CultureTipType.transport, title: 'Validate tickets', body: 'Check whether your local transit ticket needs validation.', priority: 8),
  CultureGuideItemModel(id: 'culture-it-05', type: CultureTipType.religiousPlace, title: 'Church visits', body: 'Keep voices low and respect active services.', priority: 9),
  CultureGuideItemModel(id: 'culture-it-06', type: CultureTipType.touristMistake, title: 'Ordering coffee', body: 'A cappuccino is commonly associated with breakfast rather than after dinner.', priority: 6),
  CultureGuideItemModel(id: 'culture-it-07', type: CultureTipType.safety, title: 'Crowded areas', body: 'Keep valuables secure on busy public transport and near major sights.', priority: 10),
  CultureGuideItemModel(id: 'culture-it-08', type: CultureTipType.scam, title: 'Unwanted gifts', body: 'Be cautious if strangers aggressively offer bracelets or gifts.', priority: 10),
  CultureGuideItemModel(id: 'culture-it-09', type: CultureTipType.doTip, title: 'Stand at the bar', body: 'Coffee at the bar can be a different experience and price from table service.', priority: 6),
  CultureGuideItemModel(id: 'culture-it-10', type: CultureTipType.phrase, title: 'Hello', body: 'A friendly basic greeting.', priority: 5, phraseLocal: 'Buongiorno', phrasePronunciation: 'bwon-JOR-no', phraseTranslation: 'Good morning / hello'),
  CultureGuideItemModel(id: 'culture-it-11', type: CultureTipType.phrase, title: 'Thank you', body: 'Useful everywhere.', priority: 5, phraseLocal: 'Grazie', phrasePronunciation: 'GRA-tsyeh', phraseTranslation: 'Thank you'),
  CultureGuideItemModel(id: 'culture-it-12', type: CultureTipType.phrase, title: 'How much?', body: 'Useful when shopping.', priority: 5, phraseLocal: 'Quanto costa?', phrasePronunciation: 'KWAN-toh KOS-tah', phraseTranslation: 'How much does it cost?'),
];
