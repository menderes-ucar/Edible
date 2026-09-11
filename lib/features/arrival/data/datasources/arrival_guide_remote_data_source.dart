import '../../../../core/services/supabase_service.dart';
import '../models/arrival_guide_model.dart';

class ArrivalGuideRemoteDataSource {
  Future<ArrivalGuideModel?> getGuide({
    required String countryCode,
    required String cityName,
    required String languageCode,
  }) async {
    final client = SupabaseService.client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }

    final response = await client.rpc(
      'get_arrival_guide',
      params: {
        'p_country_code': countryCode,
        'p_city_name': cityName,
        'p_locale': languageCode,
      },
    );

    if (response is! List || response.isEmpty) return null;

    return ArrivalGuideModel.fromMap(
      Map<String, dynamic>.from(response.first as Map),
    );
  }
}
