class FreeDayDiscoveryPolicy {
  const FreeDayDiscoveryPolicy._();

  static bool canAdd({
    required int stopCount,
    required int unscheduledCount,
    required bool isSaving,
  }) {
    return stopCount == 0 && unscheduledCount > 0 && !isSaving;
  }
}
