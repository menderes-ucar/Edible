import '../../../../core/services/supabase_service.dart';
import '../models/culture_guide_item_model.dart';

class CultureRemoteDataSource {
  Future<List<CultureGuideItemModel>> getGuideItems({
    required String countryCode,
    required String cityName,
    required String languageCode,
  }) async {
    final client = SupabaseService.client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }

    final response = await client.rpc(
      'get_culture_guide',
      params: {
        'p_country_code': countryCode,
        'p_city_name': cityName,
        'p_locale': languageCode,
      },
    );

    return (response as List<dynamic>)
        .map(
          (row) => CultureGuideItemModel.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
  }
}
