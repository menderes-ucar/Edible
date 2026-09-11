import '../../../../core/services/supabase_service.dart';
import '../models/explore_content_model.dart';

class ExploreRemoteDataSource {
  static const _imageBucket = 'edible-content-images';

  Future<List<ExploreContentModel>> getContents({
    required String languageCode,
  }) async {
    final client = SupabaseService.client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }

    final response = await client.rpc(
      'get_explore_contents',
      params: {'p_locale': languageCode},
    );

    return (response as List<dynamic>).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final paths = _toStringList(map['image_paths']);

      final galleryUrls = paths
          .map(
            (path) => client.storage
                .from(_imageBucket)
                .getPublicUrl(path),
          )
          .toList(growable: false);

      return ExploreContentModel.fromMap(
        map,
        resolvedGalleryUrls: galleryUrls,
      );
    }).toList(growable: false);
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return const [];
  }
}
