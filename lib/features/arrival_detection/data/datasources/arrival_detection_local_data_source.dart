import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/entities/arrival_welcome_history.dart';

class ArrivalDetectionLocalDataSource {
  const ArrivalDetectionLocalDataSource();

  Future<File> _file() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/edible_arrival');

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return File('${directory.path}/last_welcome.json');
  }

  Future<ArrivalWelcomeHistory?> getLastWelcome() async {
    final file = await _file();
    if (!await file.exists()) return null;

    try {
      final raw = await file.readAsString();
      final map = Map<String, dynamic>.from(
        jsonDecode(raw) as Map,
      );

      final shownAt = DateTime.tryParse(
        (map['shown_at'] ?? '').toString(),
      );

      if (shownAt == null) return null;

      return ArrivalWelcomeHistory(
        countryCode: (map['country_code'] ?? '').toString(),
        cityName: (map['city_name'] ?? '').toString(),
        shownAt: shownAt,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveWelcome({
    required String countryCode,
    required String cityName,
    required DateTime shownAt,
  }) async {
    final file = await _file();

    await file.writeAsString(
      jsonEncode({
        'country_code': countryCode,
        'city_name': cityName,
        'shown_at': shownAt.toIso8601String(),
      }),
      flush: true,
    );
  }
}
