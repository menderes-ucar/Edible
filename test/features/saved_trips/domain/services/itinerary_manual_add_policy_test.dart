import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/saved_trips/domain/services/itinerary_manual_edit_policy.dart';

void main() {
  test('allows adding into a day below capacity', () {
    expect(
      ItineraryManualEditPolicy.canMoveIntoDay(
        targetStopCount: 5,
        movingWithinSameDay: false,
      ),
      isTrue,
    );
  });

  test('rejects adding into a full day', () {
    expect(
      ItineraryManualEditPolicy.canMoveIntoDay(
        targetStopCount: 6,
        movingWithinSameDay: false,
      ),
      isFalse,
    );
  });

  test('moving within same day remains allowed by policy', () {
    expect(
      ItineraryManualEditPolicy.canMoveIntoDay(
        targetStopCount: 99,
        movingWithinSameDay: true,
      ),
      isTrue,
    );
  });
}
