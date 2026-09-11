import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/saved_trips/domain/services/saved_trip_mutation_policy.dart';

void main() {
  test('content save blocks update and delete for the same trip', () {
    const pending = <String>{'content:trip-a:place-1'};

    expect(
      SavedTripMutationPolicy.canStartTripWrite(
        pendingKeys: pending,
        tripId: 'trip-a',
      ),
      isFalse,
    );
  });

  test('update blocks content mutation for the same trip', () {
    const pending = <String>{'update:trip-a'};

    expect(
      SavedTripMutationPolicy.hasTripWrite(
        pendingKeys: pending,
        tripId: 'trip-a',
      ),
      isTrue,
    );
  });

  test('delete blocks every other write for the same trip', () {
    const pending = <String>{'delete:trip-a'};

    expect(
      SavedTripMutationPolicy.canStartTripWrite(
        pendingKeys: pending,
        tripId: 'trip-a',
      ),
      isFalse,
    );
  });

  test('trip-a write does not block trip-b', () {
    const pending = <String>{
      'update:trip-a',
      'content:trip-a:place-1',
    };

    expect(
      SavedTripMutationPolicy.canStartTripWrite(
        pendingKeys: pending,
        tripId: 'trip-b',
      ),
      isTrue,
    );
  });
}
