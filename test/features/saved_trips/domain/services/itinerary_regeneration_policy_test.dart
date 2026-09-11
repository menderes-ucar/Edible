import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/saved_trips/domain/services/itinerary_regeneration_policy.dart';

void main() {
  test('fresh itinerary generation does not need destructive confirmation', () {
    expect(
      ItineraryRegenerationPolicy.requiresConfirmation(
        persistedStopCount: 0,
        unresolvedStopCount: 0,
      ),
      isFalse,
    );
  });

  test('existing resolved stops require confirmation', () {
    expect(
      ItineraryRegenerationPolicy.requiresConfirmation(
        persistedStopCount: 3,
        unresolvedStopCount: 0,
      ),
      isTrue,
    );
  });

  test('unresolved persisted stops also require confirmation', () {
    expect(
      ItineraryRegenerationPolicy.requiresConfirmation(
        persistedStopCount: 0,
        unresolvedStopCount: 2,
      ),
      isTrue,
    );
  });
}
