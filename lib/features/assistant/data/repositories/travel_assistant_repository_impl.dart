import '../../domain/entities/travel_assistant_request.dart';
import '../../domain/entities/travel_assistant_response.dart';
import '../../domain/repositories/travel_assistant_repository.dart';
import '../datasources/travel_assistant_local_data_source.dart';
import '../datasources/travel_assistant_remote_data_source.dart';

class TravelAssistantRepositoryImpl implements TravelAssistantRepository {
  TravelAssistantRepositoryImpl({
    required TravelAssistantLocalDataSource localDataSource,
    TravelAssistantRemoteDataSource? remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  final TravelAssistantLocalDataSource _localDataSource;
  final TravelAssistantRemoteDataSource? _remoteDataSource;

  /// AI first; the offline engine is the safety net, so the feature never
  /// breaks when the AI service is unreachable, signed out, or over quota.
  @override
  Future<TravelAssistantResponse> ask(
    TravelAssistantRequest request,
  ) async {
    final remote = _remoteDataSource;
    if (remote != null) {
      try {
        return await remote.ask(request);
      } on AssistantQuotaExceededException {
        final basic = await _localDataSource.ask(request);
        return basic.withSource(TravelAssistantSource.basicQuotaReached);
      } catch (_) {
        // Fall through to the offline engine.
      }
    }
    return _localDataSource.ask(request);
  }
}
