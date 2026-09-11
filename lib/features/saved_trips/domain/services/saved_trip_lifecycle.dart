enum SavedTripLifecycle {
  upcoming,
  active,
  past,
}

SavedTripLifecycle savedTripLifecycle({
  required DateTime startDate,
  required DateTime endDate,
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final start = DateTime(startDate.year, startDate.month, startDate.day);
  final end = DateTime(endDate.year, endDate.month, endDate.day);

  if (today.isBefore(start)) return SavedTripLifecycle.upcoming;
  if (today.isAfter(end)) return SavedTripLifecycle.past;
  return SavedTripLifecycle.active;
}
