import '../../../../core/services/supabase_service.dart';
import '../../../offline/data/datasources/offline_city_pack_local_data_source.dart';
import '../../domain/entities/food_details.dart';
import '../../domain/repositories/food_repository.dart';
import '../datasources/food_local_data_source.dart';
import '../datasources/food_remote_data_source.dart';

class FoodRepositoryImpl implements FoodRepository {
  FoodRepositoryImpl({
    required FoodRemoteDataSource remoteDataSource,
    required FoodLocalDataSource localDataSource,
    required OfflineCityPackLocalDataSource offlineDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _offlineDataSource = offlineDataSource;

  final FoodRemoteDataSource _remoteDataSource;
  final FoodLocalDataSource _localDataSource;
  final OfflineCityPackLocalDataSource _offlineDataSource;

  @override
  Future<Map<String, FoodDetails>> getDetailsForContents({
    required Iterable<String> contentIds,
    required String languageCode,
  }) async {
    final ids = contentIds.toList(growable: false);
    if (ids.isEmpty) return const {};

    final result = <String, FoodDetails>{};

    for (final id in ids) {
      final offline = await _offlineDataSource.findFoodDetails(id);
      if (offline != null) result[id] = offline;
    }

    try {
      if (SupabaseService.client != null) {
        final remote = await _remoteDataSource.getDetailsForContents(
          contentIds: ids,
          languageCode: languageCode,
        );

        for (final detail in remote) {
          result[detail.contentId] = detail;
        }
      }
    } catch (_) {
      // Keep already loaded offline results.
    }

    final missing = ids.where((id) => !result.containsKey(id));
    final local = _localDataSource.getDetails(
      contentIds: missing,
      languageCode: languageCode,
    );

    for (final detail in local) {
      result[detail.contentId] = detail;
    }

    return result;
  }

  @override
  Future<FoodDetails?> getByContentId({
    required String contentId,
    required String languageCode,
  }) async {
    final result = await getDetailsForContents(
      contentIds: [contentId],
      languageCode: languageCode,
    );

    return result[contentId];
  }
}
