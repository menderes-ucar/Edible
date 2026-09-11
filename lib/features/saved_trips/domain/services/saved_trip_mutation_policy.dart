class SavedTripMutationPolicy {
  const SavedTripMutationPolicy._();

  static bool hasTripWrite({
    required Iterable<String> pendingKeys,
    required String tripId,
  }) {
    if (pendingKeys.contains('update:$tripId')) return true;
    if (pendingKeys.contains('delete:$tripId')) return true;

    final contentPrefix = 'content:$tripId:';
    return pendingKeys.any((key) => key.startsWith(contentPrefix));
  }

  static bool canStartTripWrite({
    required Iterable<String> pendingKeys,
    required String tripId,
  }) {
    return !hasTripWrite(
      pendingKeys: pendingKeys,
      tripId: tripId,
    );
  }
}
