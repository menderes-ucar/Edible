import '../../domain/entities/travel_assistant_request.dart';
import '../../domain/entities/travel_assistant_response.dart';
import '../../domain/repositories/travel_assistant_repository.dart';
import '../datasources/travel_assistant_local_data_source.dart';

class TravelAssistantRepositoryImpl implements TravelAssistantRepository {
  TravelAssistantRepositoryImpl({
    required TravelAssistantLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final TravelAssistantLocalDataSource _localDataSource;

  @override
  Future<TravelAssistantResponse> ask(
    TravelAssistantRequest request,
  ) {
    return _localDataSource.ask(request);
  }
}
