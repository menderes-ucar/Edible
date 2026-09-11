class ItineraryRegenerationPolicy {
  const ItineraryRegenerationPolicy._();

  static bool requiresConfirmation({
    required int persistedStopCount,
    required int unresolvedStopCount,
  }) {
    return persistedStopCount > 0 || unresolvedStopCount > 0;
  }
}
