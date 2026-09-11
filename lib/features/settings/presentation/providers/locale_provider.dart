import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import '../../../../core/localization/app_language.dart';
import '../../data/locale_storage.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider({
    LocaleStorage storage = const LocaleStorage(),
  }) : _storage = storage {
    _locale = _supportedDeviceLocale();
    unawaited(_restore());
  }

  static final availableLocales = AppLanguage.supportedLocales;

  final LocaleStorage _storage;

  late Locale _locale;
  bool _isRestored = false;
  bool _disposed = false;
  int _writeGeneration = 0;

  Locale get locale => _locale;
  bool get isRestored => _isRestored;

  Future<void> setLocale(Locale locale) async {
    if (_disposed) return;

    final normalized = _supportedLocale(locale.languageCode);
    if (normalized == null) return;

    if (_locale.languageCode == normalized.languageCode) {
      if (!_isRestored) {
        _isRestored = true;
        _notifyIfAlive();
      }
      return;
    }

    final generation = ++_writeGeneration;
    _locale = normalized;
    _isRestored = true;
    _notifyIfAlive();

    await _storage.writeLanguageCode(normalized.languageCode);

    if (_disposed || generation != _writeGeneration) return;
  }

  Future<void> _restore() async {
    final generationAtStart = _writeGeneration;
    final stored = await _storage.readLanguageCode();

    if (_disposed || generationAtStart != _writeGeneration) return;
    final restored = stored == null ? null : _supportedLocale(stored);

    if (restored != null &&
        restored.languageCode != _locale.languageCode) {
      _locale = restored;
    }

    _isRestored = true;
    _notifyIfAlive();
  }

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _writeGeneration++;
    super.dispose();
  }

  static Locale _supportedDeviceLocale() {
    final deviceCode =
        PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return _supportedLocale(deviceCode) ?? const Locale('en');
  }

  static Locale? _supportedLocale(String languageCode) {
    final normalized = languageCode.trim().toLowerCase();

    for (final locale in availableLocales) {
      if (locale.languageCode == normalized) {
        return locale;
      }
    }

    return null;
  }
}
