import 'package:flutter/material.dart';

/// Single source of truth for every UI locale supported by Edible.
///
/// Keep this list synchronized with AppLocalizations and LocaleProvider.
/// Content services may use the same language codes for Wikipedia/catalog data.
class AppLanguage {
  const AppLanguage({
    required this.locale,
    required this.name,
    required this.nativeName,
  });

  final Locale locale;
  final String name;
  final String nativeName;

  String get code => locale.languageCode;

  /// Dil adlarının her arayüz dilindeki karşılığı: [arayüzDili][dilKodu].
  static const _localizedNames = <String, Map<String, String>>{
    'en': {'en': 'English', 'tr': 'Turkish', 'de': 'German', 'fr': 'French', 'es': 'Spanish', 'it': 'Italian', 'ar': 'Arabic', 'zh': 'Chinese', 'ru': 'Russian', 'ko': 'Korean', 'ja': 'Japanese', 'pt': 'Portuguese', 'nl': 'Dutch'},
    'tr': {'en': 'İngilizce', 'tr': 'Türkçe', 'de': 'Almanca', 'fr': 'Fransızca', 'es': 'İspanyolca', 'it': 'İtalyanca', 'ar': 'Arapça', 'zh': 'Çince', 'ru': 'Rusça', 'ko': 'Korece', 'ja': 'Japonca', 'pt': 'Portekizce', 'nl': 'Felemenkçe'},
    'de': {'en': 'Englisch', 'tr': 'Türkisch', 'de': 'Deutsch', 'fr': 'Französisch', 'es': 'Spanisch', 'it': 'Italienisch', 'ar': 'Arabisch', 'zh': 'Chinesisch', 'ru': 'Russisch', 'ko': 'Koreanisch', 'ja': 'Japanisch', 'pt': 'Portugiesisch', 'nl': 'Niederländisch'},
    'fr': {'en': 'Anglais', 'tr': 'Turc', 'de': 'Allemand', 'fr': 'Français', 'es': 'Espagnol', 'it': 'Italien', 'ar': 'Arabe', 'zh': 'Chinois', 'ru': 'Russe', 'ko': 'Coréen', 'ja': 'Japonais', 'pt': 'Portugais', 'nl': 'Néerlandais'},
    'es': {'en': 'Inglés', 'tr': 'Turco', 'de': 'Alemán', 'fr': 'Francés', 'es': 'Español', 'it': 'Italiano', 'ar': 'Árabe', 'zh': 'Chino', 'ru': 'Ruso', 'ko': 'Coreano', 'ja': 'Japonés', 'pt': 'Portugués', 'nl': 'Neerlandés'},
    'it': {'en': 'Inglese', 'tr': 'Turco', 'de': 'Tedesco', 'fr': 'Francese', 'es': 'Spagnolo', 'it': 'Italiano', 'ar': 'Arabo', 'zh': 'Cinese', 'ru': 'Russo', 'ko': 'Coreano', 'ja': 'Giapponese', 'pt': 'Portoghese', 'nl': 'Olandese'},
    'ar': {'en': 'الإنجليزية', 'tr': 'التركية', 'de': 'الألمانية', 'fr': 'الفرنسية', 'es': 'الإسبانية', 'it': 'الإيطالية', 'ar': 'العربية', 'zh': 'الصينية', 'ru': 'الروسية', 'ko': 'الكورية', 'ja': 'اليابانية', 'pt': 'البرتغالية', 'nl': 'الهولندية'},
    'zh': {'en': '英语', 'tr': '土耳其语', 'de': '德语', 'fr': '法语', 'es': '西班牙语', 'it': '意大利语', 'ar': '阿拉伯语', 'zh': '中文', 'ru': '俄语', 'ko': '韩语', 'ja': '日语', 'pt': '葡萄牙语', 'nl': '荷兰语'},
    'ru': {'en': 'Английский', 'tr': 'Турецкий', 'de': 'Немецкий', 'fr': 'Французский', 'es': 'Испанский', 'it': 'Итальянский', 'ar': 'Арабский', 'zh': 'Китайский', 'ru': 'Русский', 'ko': 'Корейский', 'ja': 'Японский', 'pt': 'Португальский', 'nl': 'Нидерландский'},
    'ko': {'en': '영어', 'tr': '튀르키예어', 'de': '독일어', 'fr': '프랑스어', 'es': '스페인어', 'it': '이탈리아어', 'ar': '아랍어', 'zh': '중국어', 'ru': '러시아어', 'ko': '한국어', 'ja': '일본어', 'pt': '포르투갈어', 'nl': '네덜란드어'},
    'ja': {'en': '英語', 'tr': 'トルコ語', 'de': 'ドイツ語', 'fr': 'フランス語', 'es': 'スペイン語', 'it': 'イタリア語', 'ar': 'アラビア語', 'zh': '中国語', 'ru': 'ロシア語', 'ko': '韓国語', 'ja': '日本語', 'pt': 'ポルトガル語', 'nl': 'オランダ語'},
    'pt': {'en': 'Inglês', 'tr': 'Turco', 'de': 'Alemão', 'fr': 'Francês', 'es': 'Espanhol', 'it': 'Italiano', 'ar': 'Árabe', 'zh': 'Chinês', 'ru': 'Russo', 'ko': 'Coreano', 'ja': 'Japonês', 'pt': 'Português', 'nl': 'Holandês'},
    'nl': {'en': 'Engels', 'tr': 'Turks', 'de': 'Duits', 'fr': 'Frans', 'es': 'Spaans', 'it': 'Italiaans', 'ar': 'Arabisch', 'zh': 'Chinees', 'ru': 'Russisch', 'ko': 'Koreaans', 'ja': 'Japans', 'pt': 'Portugees', 'nl': 'Nederlands'},
  };

  /// [uiCode] arayüz dilinde bu dilin adı (ör. tr arayüzünde ru -> 'Rusça').
  String localizedName(String uiCode) =>
      _localizedNames[uiCode.toLowerCase()]?[code] ?? name;

  /// Listede gösterilecek etiket: kendi yazısı + arayüz dilindeki adı.
  /// Aynıysa (ör. Türkçe arayüzde Türkçe) tekrar etmez.
  String label(String uiCode) {
    final local = localizedName(uiCode);
    return local == nativeName ? nativeName : '$nativeName · $local';
  }

  static const all = <AppLanguage>[
    AppLanguage(locale: Locale('en'), name: 'English', nativeName: 'English'),
    AppLanguage(locale: Locale('tr'), name: 'Turkish', nativeName: 'Türkçe'),
    AppLanguage(locale: Locale('de'), name: 'German', nativeName: 'Deutsch'),
    AppLanguage(locale: Locale('fr'), name: 'French', nativeName: 'Français'),
    AppLanguage(locale: Locale('es'), name: 'Spanish', nativeName: 'Español'),
    AppLanguage(locale: Locale('it'), name: 'Italian', nativeName: 'Italiano'),
    AppLanguage(locale: Locale('ar'), name: 'Arabic', nativeName: 'العربية'),
    AppLanguage(locale: Locale('zh'), name: 'Chinese', nativeName: '中文'),
    AppLanguage(locale: Locale('ru'), name: 'Russian', nativeName: 'Русский'),
    AppLanguage(locale: Locale('ko'), name: 'Korean', nativeName: '한국어'),
    AppLanguage(locale: Locale('ja'), name: 'Japanese', nativeName: '日本語'),
    AppLanguage(locale: Locale('pt'), name: 'Portuguese', nativeName: 'Português'),
    AppLanguage(locale: Locale('nl'), name: 'Dutch', nativeName: 'Nederlands'),
  ];

  static final supportedLocales = List<Locale>.unmodifiable([
    for (final language in all) language.locale,
  ]);

  static AppLanguage? fromCode(String code) {
    final normalized = code.trim().toLowerCase().split(RegExp(r'[-_]')).first;
    for (final language in all) {
      if (language.code == normalized) return language;
    }
    return null;
  }
}
