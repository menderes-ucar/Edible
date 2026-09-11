class SavedTripDatePolicy {
  const SavedTripDatePolicy._();

  static const int maxTripDays = 30;

  static DateTime maxEndDate(DateTime startDate) {
    return startDate.add(const Duration(days: maxTripDays - 1));
  }

  static DateTime clampEndDate({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (endDate.isBefore(startDate)) return startDate;
    final maxEnd = maxEndDate(startDate);
    if (endDate.isAfter(maxEnd)) return maxEnd;
    return endDate;
  }

  static void requireValidRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (!isValidRange(startDate: startDate, endDate: endDate)) {
      throw const SavedTripDateRangeException();
    }
  }

  static bool isValidRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (endDate.isBefore(startDate)) return false;
    final days = endDate.difference(startDate).inDays + 1;
    return days >= 1 && days <= maxTripDays;
  }
}

class SavedTripDateRangeException implements Exception {
  const SavedTripDateRangeException();

  @override
  String toString() => 'SavedTripDateRangeException(invalid_trip_date_range)';
}
