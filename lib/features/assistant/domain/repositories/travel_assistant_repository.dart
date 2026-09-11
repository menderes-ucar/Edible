import '../entities/travel_assistant_request.dart';
import '../entities/travel_assistant_response.dart';

abstract interface class TravelAssistantRepository {
  Future<TravelAssistantResponse> ask(
    TravelAssistantRequest request,
  );
}
