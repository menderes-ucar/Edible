import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/saved_trips/domain/services/itinerary_manual_edit_policy.dart';

void main() {
  test('cannot move a stop into a full six-stop day', () {
    expect(
      ItineraryManualEditPolicy.canMoveIntoDay(
        targetStopCount: 6,
        movingWithinSameDay: false,
      ),
      isFalse,
    );
  });

  test('can move a stop into a day with room', () {
    expect(
      ItineraryManualEditPolicy.canMoveIntoDay(
        targetStopCount: 5,
        movingWithinSameDay: false,
      ),
      isTrue,
    );
  });

  test('time changes clamp to supported editing window', () {
    expect(
      ItineraryManualEditPolicy.adjustedMinute(
        currentMinute: 360,
        deltaMinutes: -30,
      ),
      360,
    );
    expect(
      ItineraryManualEditPolicy.adjustedMinute(
        currentMinute: 1320,
        deltaMinutes: 30,
      ),
      1320,
    );
  });

  test('clamped no-op is not reported as a real time change', () {
    expect(
      ItineraryManualEditPolicy.wouldChangeTime(
        currentMinute: 360,
        deltaMinutes: -30,
      ),
      isFalse,
    );
  });
}
