import '../../domain/entities/arrival_welcome_history.dart';
import '../../domain/repositories/arrival_detection_repository.dart';
import '../datasources/arrival_detection_local_data_source.dart';

class ArrivalDetectionRepositoryImpl
    implements ArrivalDetectionRepository {
  const ArrivalDetectionRepositoryImpl({
    required ArrivalDetectionLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final ArrivalDetectionLocalDataSource _localDataSource;

  @override
  Future<ArrivalWelcomeHistory?> getLastWelcome() {
    return _localDataSource.getLastWelcome();
  }

  @override
  Future<void> saveWelcome({
    required String countryCode,
    required String cityName,
    required DateTime shownAt,
  }) {
    return _localDataSource.saveWelcome(
      countryCode: countryCode,
      cityName: cityName,
      shownAt: shownAt,
    );
  }
}
