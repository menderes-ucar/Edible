import '../../../../core/services/supabase_service.dart';
import '../../../offline/data/datasources/offline_city_pack_local_data_source.dart';
import '../../domain/entities/culture_guide.dart';
import '../../domain/repositories/culture_repository.dart';
import '../datasources/culture_local_data_source.dart';
import '../datasources/culture_remote_data_source.dart';

class CultureRepositoryImpl implements CultureRepository {
  CultureRepositoryImpl({
    required CultureRemoteDataSource remoteDataSource,
    required CultureLocalDataSource localDataSource,
    required OfflineCityPackLocalDataSource offlineDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _offlineDataSource = offlineDataSource;

  final CultureRemoteDataSource _remoteDataSource;
  final CultureLocalDataSource _localDataSource;
  final OfflineCityPackLocalDataSource _offlineDataSource;

  @override
  Future<CultureGuide> getGuide({
    required String countryCode,
    required String cityName,
    required String languageCode,
  }) async {
    try {
      if (SupabaseService.client != null) {
        final remote = await _remoteDataSource.getGuideItems(
          countryCode: countryCode,
          cityName: cityName,
          languageCode: languageCode,
        );

        if (remote.isNotEmpty) {
          return CultureGuide(
            countryCode: countryCode,
            countryName: countryCode,
            cityName: cityName,
            items: remote,
          );
        }
      }
    } catch (_) {
      // Fall through to downloaded guide.
    }

    final offline = await _offlineDataSource.findCultureGuide(
      countryCode: countryCode,
      cityName: cityName,
      languageCode: languageCode,
    );

    if (offline != null && !offline.isEmpty) return offline;

    return _localDataSource.getGuide(
      countryCode: countryCode,
      cityName: cityName,
    );
  }
}
