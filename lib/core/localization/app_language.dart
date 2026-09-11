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
