import 'package:flutter/foundation.dart';

import '../../../explore/domain/entities/explore_content.dart';
import '../../domain/entities/trip_plan.dart';
import '../../domain/entities/trip_plan_request.dart';
import '../../domain/usecases/generate_trip_plan.dart';

class TripPlannerProvider extends ChangeNotifier {
  TripPlannerProvider({
    GenerateTripPlan generator = const GenerateTripPlan(),
  }) : _generator = generator;

  final GenerateTripPlan _generator;
  TripPlan? _plan;
  bool _disposed = false;

  TripPlan? get plan => _plan;

  void generate({
    required TripPlanRequest request,
    required Iterable<ExploreContent> contents,
  }) {
    if (_disposed) return;

    _plan = _generator(request: request, contents: contents);
    _notifyIfAlive();
  }

  void clear() {
    if (_disposed) return;

    _plan = null;
    _notifyIfAlive();
  }

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _plan = null;
    super.dispose();
  }
}
