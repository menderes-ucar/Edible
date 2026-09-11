import '../../domain/entities/country_mastery.dart';
import '../../domain/entities/country_quest.dart';
import '../../domain/entities/country_visit_badge.dart';
import '../../domain/entities/travel_dna.dart';
import '../../domain/entities/travel_year_summary.dart';
import '../../domain/repositories/visits_repository.dart';
import '../datasources/visits_remote_data_source.dart';

class VisitsRepositoryImpl implements VisitsRepository {
  const VisitsRepositoryImpl({
    required VisitsRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final VisitsRemoteDataSource _remoteDataSource;

  @override
  Future<List<CountryQuest>> getCountryQuests(String languageCode) async {
    final rows = await _remoteDataSource.getCountryQuests(languageCode);

    return rows
        .map(
          (row) => CountryQuest(
            countryCode: (row['country_code'] ?? '').toString(),
            countryName: (row['country_name'] ?? '').toString(),
            completedCount: _int(row['completed_count']),
            totalCount: _int(row['total_count']),
            nextContentId: row['next_content_id']?.toString(),
            nextTitle: row['next_title']?.toString(),
            nextCategory: row['next_category']?.toString(),
            nextCityName: row['next_city_name']?.toString(),
          ),
        )
        .where((quest) => quest.countryCode.trim().isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<List<CountryVisitBadge>> getCountryBadges() async {
    final rows = await _remoteDataSource.getCountryBadges();

    return rows
        .map(
          (row) => CountryVisitBadge(
            countryCode: (row['country_code'] ?? '').toString(),
            countryName: (row['country_name'] ?? '').toString(),
            visitCount: _int(row['visit_count']),
            cityCount: _int(row['city_count']),
            firstVisitDay: _date(row['first_visit_day']),
            lastVisitDay: _date(row['last_visit_day']),
            photoCount: _int(row['photo_count']),
            latestVisitId: (row['latest_visit_id'] ?? '').toString(),
            coverPhotoPath: row['cover_photo_path']?.toString(),
            coverPhotoUrl: row['cover_photo_url']?.toString(),
            latestLatitude: _double(row['latest_latitude']),
            latestLongitude: _double(row['latest_longitude']),
          ),
        )
        .where(
          (badge) =>
              badge.countryCode.trim().isNotEmpty &&
              badge.latestVisitId.trim().isNotEmpty,
        )
        .toList(growable: false);
  }




  @override
  Future<List<CountryMastery>> getCountryMastery() async {
    final rows = await _remoteDataSource.getCountryMastery();

    return rows
        .map(
          (row) => CountryMastery(
            countryCode: (row['country_code'] ?? '').toString(),
            countryName: (row['country_name'] ?? '').toString(),
            completedCount: _int(row['completed_count']),
            totalCount: _int(row['total_count']),
            placeCompleted: _int(row['place_completed']),
            placeTotal: _int(row['place_total']),
            tasteCompleted: _int(row['taste_completed']),
            tasteTotal: _int(row['taste_total']),
            cultureCompleted: _int(row['culture_completed']),
            cultureTotal: _int(row['culture_total']),
          ),
        )
        .where((item) => item.countryCode.trim().isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<TravelDna> getTravelDna() async {
    final row = await _remoteDataSource.getTravelDna();
    final rawCategories = row['category_counts'];

    final categories = <String, int>{};
    if (rawCategories is Map) {
      for (final entry in rawCategories.entries) {
        categories[entry.key.toString()] = _int(entry.value);
      }
    }

    return TravelDna(
      visitedCount: _int(row['visited_count']),
      triedCount: _int(row['tried_count']),
      categoryCounts: Map<String, int>.unmodifiable(categories),
    );
  }

  @override
  Future<TravelYearSummary> getYearSummary(int year) async {
    final row = await _remoteDataSource.getYearSummary(year);

    final rawYears = row['active_years'];
    final years = rawYears is List
        ? rawYears
            .map((value) => _int(value))
            .where((value) => value > 0)
            .toList(growable: false)
        : const <int>[];

    return TravelYearSummary(
      year: _int(row['year']) == 0 ? year : _int(row['year']),
      countryCount: _int(row['country_count']),
      cityCount: _int(row['city_count']),
      travelDayCount: _int(row['travel_day_count']),
      photoCount: _int(row['photo_count']),
      activeYears: years,
    );
  }

  int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double? _double(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  DateTime _date(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
