import '../../domain/entities/tour_package.dart';

/// Localizes the presentation copy of bundled tours without changing their
/// stable IDs, ratings, progress or favorite records.
TourPackage localizeTourPackage(TourPackage package, String languageCode) {
  final locale = languageCode.trim().toLowerCase().split(RegExp(r'[-_]')).first;
  final title = _title(locale, package.cityName);
  final summary = _summary(locale);
  final stops = package.stops.map((stop) => TourStop(
        id: stop.id,
        dayIndex: stop.dayIndex,
        orderIndex: stop.orderIndex,
        kind: stop.kind,
        title: stop.title,
        subtitle: _stopSubtitle(locale, stop),
        imageUrl: stop.imageUrl,
        imageAttribution: stop.imageAttribution,
        latitude: stop.latitude,
        longitude: stop.longitude,
      )).toList(growable: false);

  return TourPackage(
    id: package.id,
    countryCode: package.countryCode,
    countryName: package.countryName,
    cityName: package.cityName,
    title: title,
    summary: summary,
    days: package.days,
    coverImageUrl: package.coverImageUrl,
    coverAttribution: package.coverAttribution,
    favoriteCount: package.favoriteCount,
    ratingAverage: package.ratingAverage,
    ratingCount: package.ratingCount,
    stops: stops,
  );
}

String _title(String locale, String city) => switch (locale) {
  'tr' => '$city Öne Çıkanları',
  'de' => 'Höhepunkte von $city',
  'fr' => 'Les incontournables de $city',
  'es' => 'Lo mejor de $city',
  'it' => 'Le meraviglie di $city',
  'ar' => 'أبرز معالم $city',
  'zh' => '$city 精选之旅',
  'ru' => 'Главное в $city',
  'ko' => '$city 핵심 여행',
  'ja' => '$city ハイライト',
  'pt' => 'Destaques de $city',
  'nl' => 'Hoogtepunten van $city',
  _ => '$city Highlights',
};

String _summary(String locale) => switch (locale) {
  'tr' => 'Şehrin öne çıkan duraklarını, yerel kültürü, yemekleri ve içecekleri bir araya getiren seçilmiş günlük rota.',
  'de' => 'Eine kuratierte Route mit den wichtigsten Sehenswürdigkeiten, lokaler Kultur, Essen und Getränken.',
  'fr' => 'Un itinéraire sélectionné réunissant les lieux incontournables, la culture locale, la cuisine et les boissons.',
  'es' => 'Una ruta seleccionada con lugares destacados, cultura local, comida y bebidas.',
  'it' => 'Un itinerario selezionato con luoghi principali, cultura locale, cibo e bevande.',
  'ar' => 'مسار مختار يجمع أبرز المعالم والثقافة المحلية والطعام والمشروبات.',
  'zh' => '精选路线涵盖城市亮点、当地文化、美食与饮品。',
  'ru' => 'Подобранный маршрут с главными достопримечательностями, местной культурой, едой и напитками.',
  'ko' => '주요 명소와 현지 문화, 음식과 음료를 담은 엄선된 여행 코스입니다.',
  'ja' => '主要スポット、地域文化、料理、飲み物を組み合わせた厳選ルートです。',
  'pt' => 'Um roteiro selecionado com atrações, cultura local, comidas e bebidas.',
  'nl' => 'Een samengestelde route met hoogtepunten, lokale cultuur, eten en drinken.',
  _ => 'A curated route combining landmark visits, local culture, food and drink.',
};

String _stopSubtitle(String locale, TourStop stop) {
  final city = stop.subtitle.split(' · ').first.trim();
  final kind = switch (stop.kind) {
    TourStopKind.place => switch (locale) {
        'tr' => 'seçilmiş gezi noktası', 'de' => 'ausgewählter Ort', 'fr' => 'lieu sélectionné',
        'es' => 'lugar seleccionado', 'it' => 'luogo selezionato', 'ar' => 'موقع مختار',
        'zh' => '精选地点', 'ru' => 'выбранное место', 'ko' => '추천 명소', 'ja' => '厳選スポット',
        'pt' => 'local selecionado', 'nl' => 'geselecteerde plek', _ => 'curated place stop'},
    TourStopKind.food => switch (locale) {
        'tr' => 'seçilmiş yemek durağı', 'de' => 'ausgewählter Essensstopp', 'fr' => 'étape gastronomique',
        'es' => 'parada gastronómica', 'it' => 'tappa gastronomica', 'ar' => 'محطة طعام مختارة',
        'zh' => '精选美食站', 'ru' => 'гастрономическая остановка', 'ko' => '추천 음식 명소', 'ja' => '厳選グルメスポット',
        'pt' => 'parada gastronômica', 'nl' => 'culinaire stop', _ => 'curated food stop'},
    TourStopKind.drink => switch (locale) {
        'tr' => 'seçilmiş içecek durağı', 'de' => 'ausgewählter Getränkestopp', 'fr' => 'étape boisson',
        'es' => 'parada de bebidas', 'it' => 'tappa per bevande', 'ar' => 'محطة مشروبات مختارة',
        'zh' => '精选饮品站', 'ru' => 'остановка с напитками', 'ko' => '추천 음료 명소', 'ja' => '厳選ドリンクスポット',
        'pt' => 'parada de bebidas', 'nl' => 'drankstop', _ => 'curated drink stop'},
    TourStopKind.snack => switch (locale) {
        'tr' => 'seçilmiş atıştırmalık durağı', 'de' => 'ausgewählter Snack-Stopp', 'fr' => 'étape snack',
        'es' => 'parada de aperitivo', 'it' => 'tappa snack', 'ar' => 'محطة وجبة خفيفة',
        'zh' => '精选小吃站', 'ru' => 'остановка с закуской', 'ko' => '추천 간식 명소', 'ja' => '厳選軽食スポット',
        'pt' => 'parada de lanche', 'nl' => 'snackstop', _ => 'curated snack stop'},
    TourStopKind.culture => switch (locale) {
        'tr' => 'seçilmiş kültür durağı', 'de' => 'ausgewählter Kulturstopp', 'fr' => 'étape culturelle',
        'es' => 'parada cultural', 'it' => 'tappa culturale', 'ar' => 'محطة ثقافية مختارة',
        'zh' => '精选文化站', 'ru' => 'культурная остановка', 'ko' => '추천 문화 명소', 'ja' => '厳選文化スポット',
        'pt' => 'parada cultural', 'nl' => 'culturele stop', _ => 'curated culture stop'},
    _ => switch (locale) {
        'tr' => 'seçilmiş durak', 'de' => 'ausgewählter Stopp', 'fr' => 'étape sélectionnée',
        'es' => 'parada seleccionada', 'it' => 'tappa selezionata', 'ar' => 'محطة مختارة',
        'zh' => '精选站点', 'ru' => 'выбранная остановка', 'ko' => '추천 장소', 'ja' => '厳選スポット',
        'pt' => 'parada selecionada', 'nl' => 'geselecteerde stop', _ => 'curated stop'},
  };
  return '$city · $kind';
}
