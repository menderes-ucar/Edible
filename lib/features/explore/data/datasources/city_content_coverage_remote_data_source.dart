
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/country_city_coverage.dart';

class CityContentCoverageRemoteDataSource {
  const CityContentCoverageRemoteDataSource();

  Future<List<CountryCityCoverage>> countryCoverage() async {
    final client = SupabaseService.client;
    if (client == null) return const [];

    final rows = await client
        .from('country_city_release_coverage')
        .select()
        .order('country_code');

    return rows.map<CountryCityCoverage>((raw) {
      final row = Map<String, dynamic>.from(raw);
      return CountryCityCoverage(
        countryCode: row['country_code'].toString(),
        cityCount: (row['city_count'] as num?)?.toInt() ?? 0,
        readyCityCount: (row['ready_city_count'] as num?)?.toInt() ?? 0,
        incompleteCityCount: (row['incomplete_city_count'] as num?)?.toInt() ?? 0,
        readyPercent: (row['ready_percent'] as num?)?.toDouble() ?? 0,
      );
    }).toList(growable: false);
  }
}
