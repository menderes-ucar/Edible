import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/entities/dietary_profile.dart';

/// Stores the food profile on this device only (never uploaded).
class DietaryProfileStorage {
  const DietaryProfileStorage();

  static const _fileName = 'edible_dietary_profile.json';

  Future<File> _file() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return File('${directory.path}/$_fileName');
  }

  Future<DietaryProfile?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return null;
      return DietaryProfile.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> write(DietaryProfile profile) async {
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode(profile.toJson()), flush: true);
    } catch (_) {
      // Persistence must never break the UI; the in-memory profile still works.
    }
  }
}
