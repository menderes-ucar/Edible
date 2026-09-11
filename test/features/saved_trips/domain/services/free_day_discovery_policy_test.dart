import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/saved_trips/domain/services/free_day_discovery_policy.dart';

void main() {
  test('allows adding when day is empty and unscheduled discoveries exist', () {
    expect(
      FreeDayDiscoveryPolicy.canAdd(
        stopCount: 0,
        unscheduledCount: 2,
        isSaving: false,
      ),
      isTrue,
    );
  });

  test('does not offer free-day action when the day already has stops', () {
    expect(
      FreeDayDiscoveryPolicy.canAdd(
        stopCount: 1,
        unscheduledCount: 2,
        isSaving: false,
      ),
      isFalse,
    );
  });

  test('does not offer action while itinerary mutation is saving', () {
    expect(
      FreeDayDiscoveryPolicy.canAdd(
        stopCount: 0,
        unscheduledCount: 2,
        isSaving: true,
      ),
      isFalse,
    );
  });

  test('does not offer action when nothing remains unscheduled', () {
    expect(
      FreeDayDiscoveryPolicy.canAdd(
        stopCount: 0,
        unscheduledCount: 0,
        isSaving: false,
      ),
      isFalse,
    );
  });
}
