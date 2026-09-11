import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../arrival_detection/domain/entities/detected_arrival.dart';
import '../../domain/entities/travel_visit.dart';

class TravelHistoryLocalDataSource {
  const TravelHistoryLocalDataSource();

  Future<File> _file() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/edible_travel_history');

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return File('${directory.path}/visits.json');
  }

  Future<List<TravelVisit>> getVisits() async {
    final file = await _file();
    if (!await file.exists()) return const [];

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];

      final visits = decoded
          .whereType<Map>()
          .map((raw) => _fromMap(Map<String, dynamic>.from(raw)))
          .whereType<TravelVisit>()
          .toList(growable: false);

      visits.sort(
        (a, b) => b.lastSeenAt.compareTo(a.lastSeenAt),
      );

      return visits;
    } catch (_) {
      return const [];
    }
  }


  Future<void> clearVisits() async {
    final file = await _file();
    if (!await file.exists()) return;
    await file.delete();
  }

  Future<void> recordArrival({
    required DetectedArrival arrival,
    required double latitude,
    required double longitude,
  }) async {
    final now = DateTime.now();
    final visitDay = DateTime(now.year, now.month, now.day);
    final visits = [...await getVisits()];

    final index = visits.indexWhere(
      (visit) =>
          _sameDay(visit.visitDay, visitDay) &&
          visit.countryCode.toLowerCase() ==
              arrival.countryCode.toLowerCase() &&
          visit.cityName.toLowerCase() ==
              arrival.cityName.toLowerCase(),
    );

    final updated = TravelVisit(
      id: index >= 0
          ? visits[index].id
          : '${arrival.countryCode}_${arrival.cityName}_${visitDay.toIso8601String()}',
      countryCode: arrival.countryCode,
      countryName: arrival.countryName,
      cityName: arrival.cityName,
      visitDay: visitDay,
      firstSeenAt: index >= 0 ? visits[index].firstSeenAt : now,
      lastSeenAt: now,
      detectionCount:
          index >= 0 ? visits[index].detectionCount + 1 : 1,
      latitude: latitude,
      longitude: longitude,
    );

    if (index >= 0) {
      visits[index] = updated;
    } else {
      visits.insert(0, updated);
    }

    final file = await _file();
    await file.writeAsString(
      jsonEncode(visits.map(_toMap).toList(growable: false)),
      flush: true,
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  Map<String, dynamic> _toMap(TravelVisit visit) {
    return {
      'id': visit.id,
      'country_code': visit.countryCode,
      'country_name': visit.countryName,
      'city_name': visit.cityName,
      'visit_day': visit.visitDay.toIso8601String(),
      'first_seen_at': visit.firstSeenAt.toIso8601String(),
      'last_seen_at': visit.lastSeenAt.toIso8601String(),
      'detection_count': visit.detectionCount,
      'latitude': visit.latitude,
      'longitude': visit.longitude,
    };
  }

  TravelVisit? _fromMap(Map<String, dynamic> map) {
    final visitDay = DateTime.tryParse(
      (map['visit_day'] ?? '').toString(),
    );
    final firstSeenAt = DateTime.tryParse(
      (map['first_seen_at'] ?? '').toString(),
    );
    final lastSeenAt = DateTime.tryParse(
      (map['last_seen_at'] ?? '').toString(),
    );

    if (visitDay == null ||
        firstSeenAt == null ||
        lastSeenAt == null) {
      return null;
    }

    return TravelVisit(
      id: (map['id'] ?? '').toString(),
      countryCode: (map['country_code'] ?? '').toString(),
      countryName: (map['country_name'] ?? '').toString(),
      cityName: (map['city_name'] ?? '').toString(),
      visitDay: visitDay,
      firstSeenAt: firstSeenAt,
      lastSeenAt: lastSeenAt,
      detectionCount: int.tryParse(
            (map['detection_count'] ?? '1').toString(),
          ) ??
          1,
      latitude: double.tryParse(
        (map['latitude'] ?? '').toString(),
      ),
      longitude: double.tryParse(
        (map['longitude'] ?? '').toString(),
      ),
    );
  }
}
