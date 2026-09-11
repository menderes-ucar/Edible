import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/saved_trips/domain/services/saved_trip_lifecycle.dart';

void main() {
  final now = DateTime(2026, 9, 4, 18, 30);

  test('future trip is upcoming', () {
    expect(
      savedTripLifecycle(
        startDate: DateTime(2026, 9, 5),
        endDate: DateTime(2026, 9, 8),
        now: now,
      ),
      SavedTripLifecycle.upcoming,
    );
  });

  test('start and end dates are active inclusively', () {
    expect(
      savedTripLifecycle(
        startDate: DateTime(2026, 9, 4),
        endDate: DateTime(2026, 9, 4),
        now: now,
      ),
      SavedTripLifecycle.active,
    );
  });

  test('finished trip is past', () {
    expect(
      savedTripLifecycle(
        startDate: DateTime(2026, 8, 28),
        endDate: DateTime(2026, 9, 3),
        now: now,
      ),
      SavedTripLifecycle.past,
    );
  });
}
