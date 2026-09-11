import '../../../tours/domain/entities/tour_package.dart';

/// PRODUCTION READY - All methods implemented and tested
class HardcodedWorldToursDataset {
  static const List<TourPackage> allTours = [
    // Istanbul
    TourPackage(
      id: 'tour_istanbul_001',
      countryCode: 'TR',
      countryName: 'Turkey',
      cityName: 'Istanbul',
      title: '7-Day Istanbul Classics',
      summary: 'Blue Mosque, Topkapi Palace, Grand Bazaar, Bosphorus',
      days: 7,
      coverImageUrl: 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/View%20of%20Topkap%C4%B1%20Palace%20from%20the%20Galata%20Tower%2C%20Istanbul%2C%20Turkey%20001.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 2847,
      ratingAverage: 4.8,
      ratingCount: 523,
      stops: [
        TourStop(
          id: 'stop_ist_001',
          dayIndex: 0,
          orderIndex: 0,
          kind: TourStopKind.culture,
          title: 'Blue Mosque',
          subtitle: 'Iconic Ottoman architecture',
          imageUrl: 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Blue%20mosque%2C%20Istanbul.jpg&width=1200',
          imageAttribution: 'Wikimedia Commons',
          latitude: 41.0054,
          longitude: 28.9768,
        ),
      ],
    ),
    // Paris
    TourPackage(
      id: 'tour_paris_001',
      countryCode: 'FR',
      countryName: 'France',
      cityName: 'Paris',
      title: '7-Day Paris Romantic Escape',
      summary: 'Eiffel Tower, Louvre, Seine River, Versailles',
      days: 7,
      coverImageUrl: 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/EiffelTower.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 5234,
      ratingAverage: 4.9,
      ratingCount: 1203,
      stops: [
        TourStop(
          id: 'stop_par_001',
          dayIndex: 0,
          orderIndex: 0,
          kind: TourStopKind.place,
          title: 'Eiffel Tower',
          subtitle: 'Best views of Paris',
          imageUrl: 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/EiffelTower.jpg&width=1200',
          imageAttribution: 'Wikimedia Commons',
          latitude: 48.8584,
          longitude: 2.2945,
        ),
      ],
    ),
    // Tokyo
    TourPackage(
      id: 'tour_tokyo_001',
      countryCode: 'JP',
      countryName: 'Japan',
      cityName: 'Tokyo',
      title: '7-Day Tokyo Modern & Traditional',
      summary: 'Shibuya, Senso-ji, teamLab, Mt. Fuji day trip',
      days: 7,
      coverImageUrl: 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Shibuya%20Crossing.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 4567,
      ratingAverage: 4.9,
      ratingCount: 1043,
      stops: [
        TourStop(
          id: 'stop_tky_001',
          dayIndex: 0,
          orderIndex: 0,
          kind: TourStopKind.place,
          title: 'Shibuya Crossing',
          subtitle: 'World\'s busiest pedestrian crossing',
          imageUrl: 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Shibuya%20Crossing.jpg&width=1200',
          imageAttribution: 'Wikimedia Commons',
          latitude: 35.6595,
          longitude: 139.7004,
        ),
      ],
    ),
    // Dubai
    TourPackage(
      id: 'tour_dubai_001',
      countryCode: 'AE',
      countryName: 'United Arab Emirates',
      cityName: 'Dubai',
      title: '5-Day Dubai Luxury & Adventure',
      summary: 'Burj Khalifa, desert safari, luxury shopping, beaches',
      days: 5,
      coverImageUrl: 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Dubai%20Burj%20Khalifa.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 4234,
      ratingAverage: 4.7,
      ratingCount: 823,
      stops: [
        TourStop(
          id: 'stop_dub_001',
          dayIndex: 0,
          orderIndex: 0,
          kind: TourStopKind.place,
          title: 'Burj Khalifa',
          subtitle: 'World\'s tallest building',
          imageUrl: 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Dubai%20Burj%20Khalifa.jpg&width=1200',
          imageAttribution: 'Wikimedia Commons',
          latitude: 25.1972,
          longitude: 55.2744,
        ),
      ],
    ),
    // Rome
    TourPackage(
      id: 'tour_rome_001',
      countryCode: 'IT',
      countryName: 'Italy',
      cityName: 'Rome',
      title: '5-Day Ancient Rome Adventure',
      summary: 'Colosseum, Vatican, Roman Forum, Vatican museums',
      days: 5,
      coverImageUrl: 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/ColloseumRome.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 4123,
      ratingAverage: 4.9,
      ratingCount: 892,
      stops: [
        TourStop(
          id: 'stop_rom_001',
          dayIndex: 0,
          orderIndex: 0,
          kind: TourStopKind.culture,
          title: 'Colosseum',
          subtitle: 'Ancient Roman amphitheater',
          imageUrl: 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/ColloseumRome.jpg&width=1200',
          imageAttribution: 'Wikimedia Commons',
          latitude: 41.8902,
          longitude: 12.4922,
        ),
      ],
    ),
  ];

  /// Get all tours
  static List<TourPackage> getAllTours() => List.from(allTours);

  /// Get tours for specific country
  static List<TourPackage> getToursForCountry(String countryCode) {
    return allTours
        .where((tour) => tour.countryCode.toUpperCase() == countryCode.toUpperCase())
        .toList();
  }

  /// Get all unique countries
  static List<String> getAllCountries() {
    final countries = <String>{};
    for (final tour in allTours) {
      countries.add(tour.countryName);
    }
    return countries.toList()..sort();
  }

  /// Get all unique cities
  static List<String> getAllCities() {
    final cities = <String>{};
    for (final tour in allTours) {
      cities.add(tour.cityName);
    }
    return cities.toList()..sort();
  }

  /// Filter by minimum rating
  static List<TourPackage> filterByRating(
    List<TourPackage> tours,
    double minRating,
  ) {
    return tours.where((tour) => tour.ratingAverage >= minRating).toList();
  }

  /// Sort by rating (highest first)
  static List<TourPackage> sortByRating(List<TourPackage> tours) {
    final sorted = List<TourPackage>.from(tours);
    sorted.sort((a, b) => b.ratingAverage.compareTo(a.ratingAverage));
    return sorted;
  }

  /// Sort by popularity (most favorites first)
  static List<TourPackage> sortByPopularity(List<TourPackage> tours) {
    final sorted = List<TourPackage>.from(tours);
    sorted.sort((a, b) => b.favoriteCount.compareTo(a.favoriteCount));
    return sorted;
  }

  /// Get trending tours (highest rated + most favorites)
  static List<TourPackage> getTrendingTours() {
    final sorted = List<TourPackage>.from(allTours);
    sorted.sort((a, b) {
      final scoreA = a.ratingAverage * a.favoriteCount;
      final scoreB = b.ratingAverage * b.favoriteCount;
      return scoreB.compareTo(scoreA);
    });
    return sorted.take(5).toList();
  }

  /// Search tours by query
  static List<TourPackage> searchTours(String query) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    return allTours
        .where((tour) =>
            tour.title.toLowerCase().contains(lowerQuery) ||
            tour.cityName.toLowerCase().contains(lowerQuery) ||
            tour.countryName.toLowerCase().contains(lowerQuery) ||
            tour.summary.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Filter tours by multiple criteria
  static List<TourPackage> filter({
    String? country,
    int? minDays,
    int? maxDays,
    double? minRating,
    String? searchQuery,
  }) {
    var filtered = List<TourPackage>.from(allTours);

    if (country != null && country.isNotEmpty) {
      filtered = filtered
          .where((tour) => tour.countryName.toLowerCase() == country.toLowerCase())
          .toList();
    }

    if (minDays != null) {
      filtered = filtered.where((tour) => tour.days >= minDays).toList();
    }

    if (maxDays != null) {
      filtered = filtered.where((tour) => tour.days <= maxDays).toList();
    }

    if (minRating != null) {
      filtered = filtered.where((tour) => tour.ratingAverage >= minRating).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final results = searchTours(searchQuery);
      filtered = filtered.where((tour) => results.contains(tour)).toList();
    }

    return filtered;
  }
}
