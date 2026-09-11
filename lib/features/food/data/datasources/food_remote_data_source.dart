import '../../../../core/services/supabase_service.dart';
import '../models/food_details_model.dart';

class FoodRemoteDataSource {
  Future<List<FoodDetailsModel>> getDetailsForContents({
    required Iterable<String> contentIds,
    required String languageCode,
  }) async {
    final client = SupabaseService.client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }

    final ids = contentIds.toList(growable: false);
    if (ids.isEmpty) return const [];

    final response = await client.rpc(
      'get_food_details',
      params: {
        'p_content_ids': ids,
        'p_locale': languageCode,
      },
    );

    return (response as List<dynamic>)
        .map(
          (row) => FoodDetailsModel.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
  }
}
