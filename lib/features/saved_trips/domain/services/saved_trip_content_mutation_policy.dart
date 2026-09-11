class SavedTripContentMutationPolicy {
  const SavedTripContentMutationPolicy._();

  static bool hasPendingMutation({
    required Iterable<String> pendingKeys,
    required String tripId,
  }) {
    final prefix = 'content:$tripId:';
    return pendingKeys.any((key) => key.startsWith(prefix));
  }

  static bool canStartMutation({
    required Iterable<String> pendingKeys,
    required String tripId,
  }) {
    return !hasPendingMutation(
      pendingKeys: pendingKeys,
      tripId: tripId,
    );
  }
}
