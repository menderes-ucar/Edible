import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/saved_trips/domain/services/itinerary_day_planning_policy.dart';

void main() {
  test('allows adding to a partially planned day', () {
    expect(
      ItineraryDayPlanningPolicy.canAdd(
        stopCount: 4,
        maxStopsPerDay: 6,
        unscheduledCount: 2,
        isSaving: false,
      ),
      isTrue,
    );
  });

  test('blocks adding when day reached capacity', () {
    expect(
      ItineraryDayPlanningPolicy.canAdd(
        stopCount: 6,
        maxStopsPerDay: 6,
        unscheduledCount: 2,
        isSaving: false,
      ),
      isFalse,
    );
    expect(
      ItineraryDayPlanningPolicy.isFull(
        stopCount: 6,
        maxStopsPerDay: 6,
      ),
      isTrue,
    );
  });

  test('blocks action when no unscheduled discovery remains', () {
    expect(
      ItineraryDayPlanningPolicy.canAdd(
        stopCount: 3,
        maxStopsPerDay: 6,
        unscheduledCount: 0,
        isSaving: false,
      ),
      isFalse,
    );
  });

  test('fill ratio is clamped to safe progress range', () {
    expect(
      ItineraryDayPlanningPolicy.fillRatio(
        stopCount: 3,
        maxStopsPerDay: 6,
      ),
      0.5,
    );
    expect(
      ItineraryDayPlanningPolicy.fillRatio(
        stopCount: 9,
        maxStopsPerDay: 6,
      ),
      1.0,
    );
  });
}
