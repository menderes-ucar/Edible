import '../../explore/domain/entities/explore_content.dart';

/// Shared parsing helpers for the assistant (used by the AI request builder and
/// by the offline fallback). Keyword lists are substring matches on the
/// lower-cased message and cover all 13 app languages.
abstract final class AssistantTextUtils {
  static const _cheap = <String>[
    'cheap', 'budget', 'ucuz', 'ekonomik', 'günstig', 'billig', 'pas cher',
    'économique', 'barato', 'económico', 'economico', 'presupuesto', 'conveniente',
    'رخيص', 'اقتصادي', '便宜', '经济', '预算', '平价', 'дешев', 'бюджет',
    'недорог', '저렴', '싼', '가성비', '安い', '格安', '予算', 'リーズナブル',
    'econômico', 'orçamento', 'goedkoop', 'voordelig',
  ];

  static const _food = <String>[
    'food', 'eat', 'restaurant', 'yemek', 'ye', 'tat', 'ramen', 'essen',
    'küche', 'manger', 'cuisine', 'gastronom', 'comer', 'comida', 'restaurante',
    'mangiare', 'cibo', 'ristorante', 'cucina', 'طعام', 'أكل', 'مطعم', 'مأكولات',
    '美食', '吃', '餐厅', '小吃', 'еда', 'поесть', 'ресторан', 'кухн', '음식',
    '먹', '맛집', '식당', '食べ', '料理', 'グルメ', 'レストラン', 'culinária',
    'eten', 'keuken',
  ];

  static const _culture = <String>[
    'culture', 'historic', 'history', 'museum', 'kültür', 'tarih', 'müze',
    'kultur', 'geschichte', 'historisch', 'histoire', 'musée', 'historique',
    'cultura', 'historia', 'museo', 'storia', 'storico', 'ثقاف', 'تاريخ',
    'متحف', '文化', '历史', '博物馆', 'культур', 'истори', 'музей', '문화',
    '역사', '박물관', '歴史', '博物館', 'história', 'museu', 'cultuur',
    'geschiedenis',
  ];

  static const _lowWalking = <String>[
    'less walking', 'low walking', 'az yürü', 'çok yürümek istemiyorum',
    'wenig laufen', 'nicht viel laufen', 'wenig gehen', 'peu de marche',
    'pas trop marcher', 'moins marcher', 'poco caminar', 'caminar poco',
    'sin caminar mucho', 'poco da camminare', 'non troppo a piedi',
    'camminare poco', 'مشي قليل', 'دون مشي كثير', 'قليل من المشي', '少走路',
    '不想走太多', '走路少', 'мало ходить', 'не ходить много', 'меньше ходить',
    '적게 걷', '많이 걷지', '걷기 싫', '歩きたくない', 'あまり歩かない',
    'pouco andar', 'andar pouco', 'sem andar muito', 'weinig lopen',
    'niet veel lopen', 'minder lopen',
  ];

  // Number followed by an hour word in any supported language. The negative
  // look-ahead stops "5 hotels" from being read as "5 h".
  static final _hours = RegExp(
    r'(\d{1,2})\s*(hour|hours|saat|stunden|stunde|std|heures|heure|horas|hora|ore|ora|ساعات|ساعة|小时|小時|часа|часов|час|시간|時間|uren|uur|h)(?![a-z])',
  );

  static bool wantsCheap(String message) => _any(message, _cheap);
  static bool wantsFood(String message) => _any(message, _food);
  static bool wantsCulture(String message) => _any(message, _culture);
  static bool wantsLowWalking(String message) => _any(message, _lowWalking);

  static int resolveHours(String message) {
    final match = _hours.firstMatch(message);
    if (match != null) {
      final value = int.tryParse(match.group(1) ?? '');
      if (value != null) return value.clamp(2, 12);
    }
    return 4;
  }

  static String resolveCity({
    required String message,
    required List<ExploreContent> all,
    String? fallback,
  }) {
    final cities = all.map((item) => item.cityName).toSet().toList();

    for (final city in cities) {
      if (message.contains(city.toLowerCase())) return city;
    }

    if (fallback != null && fallback.trim().isNotEmpty) return fallback;
    return cities.isNotEmpty ? cities.first : '';
  }

  static bool _any(String message, List<String> values) =>
      values.any(message.contains);
}
