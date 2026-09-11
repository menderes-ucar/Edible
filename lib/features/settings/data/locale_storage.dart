import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocaleStorage {
  const LocaleStorage();

  static const _fileName = 'edible_locale.txt';

  Future<String?> readLanguageCode() async {
    try {
      final directory = await getApplicationSupportDirectory();
      await directory.create(recursive: true);
      final file = File('${directory.path}/$_fileName');
      if (!await file.exists()) return null;

      final value = (await file.readAsString()).trim().toLowerCase();
      return value.isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeLanguageCode(String languageCode) async {
    try {
      final directory = await getApplicationSupportDirectory();
      await directory.create(recursive: true);
      final file = File('${directory.path}/$_fileName');
      await file.writeAsString(languageCode.trim().toLowerCase(), flush: true);
    } catch (_) {
      // Locale persistence must never prevent the app from running.
    }
  }
}
