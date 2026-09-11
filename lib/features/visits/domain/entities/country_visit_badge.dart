class CountryVisitBadge {
  const CountryVisitBadge({
    required this.countryCode,
    required this.countryName,
    required this.visitCount,
    required this.cityCount,
    required this.firstVisitDay,
    required this.lastVisitDay,
    required this.photoCount,
    required this.latestVisitId,
    this.coverPhotoPath,
    this.coverPhotoUrl,
    this.latestLatitude,
    this.latestLongitude,
  });

  final String countryCode;
  final String countryName;
  final int visitCount;
  final int cityCount;
  final DateTime firstVisitDay;
  final DateTime lastVisitDay;
  final int photoCount;
  final String latestVisitId;

  /// Private Storage object path selected from this user's Travel Memories.
  final String? coverPhotoPath;

  /// Ephemeral signed URL generated client-side for rendering only.
  final String? coverPhotoUrl;

  /// Latest recorded visit coordinate for the country's map marker.
  final double? latestLatitude;
  final double? latestLongitude;

  /// A visited-country badge shines only when at least one persisted
  /// Travel Memory photo exists for that country's real visits.
  bool get isShining => photoCount > 0;

  /// Backward-compatible alias used by the existing milestone/passport UI.
  bool get isUnlocked => isShining;

  bool get hasPhotoProof => photoCount > 0;

  bool get hasCoverPhoto =>
      (coverPhotoPath ?? '').trim().isNotEmpty &&
      (coverPhotoUrl ?? '').trim().isNotEmpty;

  bool get hasMapLocation {
    final lat = latestLatitude;
    final lng = latestLongitude;
    return lat != null &&
        lng != null &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  String get normalizedCountryCode => countryCode.trim().toUpperCase();
}
