import 'package:flutter_test/flutter_test.dart';

import 'package:edible/features/saved_trips/domain/services/saved_trip_date_policy.dart';

void main() {
  test('accepts one-day and thirty-day trips', () {
    final start = DateTime(2026, 10, 1);

    expect(
      SavedTripDatePolicy.isValidRange(
        startDate: start,
        endDate: start,
      ),
      isTrue,
    );
    expect(
      SavedTripDatePolicy.isValidRange(
        startDate: start,
        endDate: start.add(const Duration(days: 29)),
      ),
      isTrue,
    );
  });

  test('rejects reversed and thirty-one-day trips', () {
    final start = DateTime(2026, 10, 1);

    expect(
      SavedTripDatePolicy.isValidRange(
        startDate: start,
        endDate: start.subtract(const Duration(days: 1)),
      ),
      isFalse,
    );
    expect(
      SavedTripDatePolicy.isValidRange(
        startDate: start,
        endDate: start.add(const Duration(days: 30)),
      ),
      isFalse,
    );
  });

  test('clamps an old end date after the start date changes', () {
    final start = DateTime(2026, 11, 1);
    final end = DateTime(2027, 1, 1);

    expect(
      SavedTripDatePolicy.clampEndDate(
        startDate: start,
        endDate: end,
      ),
      DateTime(2026, 11, 30),
    );
  });

  test('requireValidRange throws before persistence for invalid range', () {
    final start = DateTime(2026, 10, 1);

    expect(
      () => SavedTripDatePolicy.requireValidRange(
        startDate: start,
        endDate: start.add(const Duration(days: 30)),
      ),
      throwsA(isA<SavedTripDateRangeException>()),
    );
  });
}
