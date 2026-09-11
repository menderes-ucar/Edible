import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/saved_trips/domain/services/saved_trip_content_mutation_policy.dart';

void main() {
  test('different content ids in the same trip share one mutation lock', () {
    const pending = <String>{'content:trip-a:place-1'};

    expect(
      SavedTripContentMutationPolicy.canStartMutation(
        pendingKeys: pending,
        tripId: 'trip-a',
      ),
      isFalse,
    );
  });

  test('a mutation in another trip does not block this trip', () {
    const pending = <String>{'content:trip-b:place-1'};

    expect(
      SavedTripContentMutationPolicy.canStartMutation(
        pendingKeys: pending,
        tripId: 'trip-a',
      ),
      isTrue,
    );
  });

  test('update and delete pending keys do not masquerade as content mutation', () {
    const pending = <String>{'update:trip-a', 'delete:trip-a'};

    expect(
      SavedTripContentMutationPolicy.hasPendingMutation(
        pendingKeys: pending,
        tripId: 'trip-a',
      ),
      isFalse,
    );
  });
}
