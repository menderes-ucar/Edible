class SavedTrip {
  const SavedTrip({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.countryName,
    required this.cityName,
    required this.startDate,
    required this.endDate,
    required this.notes,
    required this.contentIds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String countryCode;
  final String countryName;
  final String cityName;
  final DateTime startDate;
  final DateTime endDate;
  final String notes;
  final List<String> contentIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get dayCount {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(start).inDays + 1;
  }

  bool get isSingleDay => dayCount <= 1;
}
