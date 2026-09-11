
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/catalog_city.dart';
import '../../domain/services/location_display_name_service.dart';

class GlobalCityRemoteDataSource {
  const GlobalCityRemoteDataSource({
    LocationDisplayNameService names = const LocationDisplayNameService(),
  }) : _names = names;

  final LocationDisplayNameService _names;

  Future<List<CatalogCity>> citiesForCountry({
    required String countryCode,
    required String locale,
    int limit = 100,
    int offset = 0,
    String query = '',
  }) async {
    final client = SupabaseService.client;
    if (client == null) return const [];

    var request = client
        .from('cities')
        .select('id,default_name,ascii_name,native_name,latitude,longitude,population,countries!inner(code)')
        .eq('countries.code', countryCode.toUpperCase());

    final q = query.trim();
    if (q.isNotEmpty) {
      request = request.or(
        'default_name.ilike.%$q%,ascii_name.ilike.%$q%,native_name.ilike.%$q%',
      );
    }

    final rows = await request
        .order('population', ascending: false, nullsFirst: false)
        .range(offset, offset + limit - 1);

    return rows.map<CatalogCity>((raw) {
      final row = Map<String, dynamic>.from(raw);
      final country = Map<String, dynamic>.from(row['countries'] as Map);
      final fallback = (row['default_name'] ?? '').toString();
      final ascii = row['ascii_name']?.toString();
      final native = row['native_name']?.toString();

      return CatalogCity(
        id: row['id'].toString(),
        countryCode: (country['code'] ?? countryCode).toString(),
        displayName: _names.cityName(
          locale: locale,
          fallbackName: fallback,
          asciiName: ascii,
          nativeName: native,
        ),
        nativeName: native,
        latitude: (row['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (row['longitude'] as num?)?.toDouble() ?? 0,
        population: (row['population'] as num?)?.toInt(),
      );
    }).toList(growable: false);
  }
}
