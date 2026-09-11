import '../entities/explore_content.dart';

abstract interface class ExploreRepository {
  Future<List<ExploreContent>> getContents({
    required String languageCode,
  });

  Future<ExploreContent?> getById({
    required String id,
    required String languageCode,
  });
}
