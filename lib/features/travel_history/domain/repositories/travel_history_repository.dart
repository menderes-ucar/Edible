import '../../../arrival_detection/domain/entities/detected_arrival.dart';
import '../entities/travel_visit.dart';

abstract interface class TravelHistoryRepository {
  Future<List<TravelVisit>> getVisits();

  Future<void> recordArrival({
    required DetectedArrival arrival,
    required double latitude,
    required double longitude,
  });
}
