import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/arrival_guide.dart';
import '../../domain/repositories/arrival_guide_repository.dart';
import '../datasources/arrival_guide_local_data_source.dart';
import '../datasources/arrival_guide_remote_data_source.dart';

class ArrivalGuideRepositoryImpl implements ArrivalGuideRepository {
  ArrivalGuideRepositoryImpl({
    required ArrivalGuideRemoteDataSource remoteDataSource,
    required ArrivalGuideLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final ArrivalGuideRemoteDataSource _remoteDataSource;
  final ArrivalGuideLocalDataSource _localDataSource;

  @override
  Future<ArrivalGuide> getGuide({
    required String countryCode,
    required String cityName,
    required String languageCode,
  }) async {
    try {
      if (SupabaseService.client != null) {
        final remote = await _remoteDataSource.getGuide(
          countryCode: countryCode,
          cityName: cityName,
          languageCode: languageCode,
        );

        if (remote != null && !remote.isEmpty) {
          return remote;
        }
      }
    } catch (_) {
      // Local fallback keeps guest/offline development usable.
    }

    return _localDataSource.getGuide(
      countryCode: countryCode,
      cityName: cityName,
    );
  }
}
