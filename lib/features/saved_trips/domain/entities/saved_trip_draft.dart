class SavedTripDraft {
  const SavedTripDraft({
    required this.name,
    required this.countryCode,
    required this.countryName,
    required this.cityName,
    required this.startDate,
    required this.endDate,
    required this.notes,
  });

  final String name;
  final String countryCode;
  final String countryName;
  final String cityName;
  final DateTime startDate;
  final DateTime endDate;
  final String notes;
}
