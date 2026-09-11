class ItineraryDayPlanningPolicy {
  const ItineraryDayPlanningPolicy._();

  static bool canAdd({
    required int stopCount,
    required int maxStopsPerDay,
    required int unscheduledCount,
    required bool isSaving,
  }) {
    return stopCount >= 0 &&
        stopCount < maxStopsPerDay &&
        unscheduledCount > 0 &&
        !isSaving;
  }

  static double fillRatio({
    required int stopCount,
    required int maxStopsPerDay,
  }) {
    if (maxStopsPerDay <= 0) return 0;
    return (stopCount / maxStopsPerDay).clamp(0.0, 1.0);
  }

  static bool isFull({
    required int stopCount,
    required int maxStopsPerDay,
  }) =>
      maxStopsPerDay > 0 && stopCount >= maxStopsPerDay;
}
