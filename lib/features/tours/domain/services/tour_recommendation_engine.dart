import '../entities/tour_package.dart';
import '../../data/datasources/hardcoded_world_tours_dataset.dart';

/// AI-Like recommendation engine using smart filtering
class TourRecommendationEngine {
  /// Filter recommendations based on user preferences
  static List<TourPackage> getRecommendations({
    required String? preferredCountry,
    required int? preferredDuration,
    required String? travelStyle, // 'luxury', 'budget', 'adventure', 'culture', 'food'
    required double? minRating,
    bool sortByPopularity = false,
  }) {
    var tours = List<TourPackage>.from(
      HardcodedWorldToursDataset.allTours,
    );

    // Filter by country if specified
    if (preferredCountry != null && preferredCountry.isNotEmpty) {
      tours = tours
          .where((tour) =>
              tour.countryName.toLowerCase() ==
              preferredCountry.toLowerCase())
          .toList();
    }

    // Filter by duration if specified
    if (preferredDuration != null) {
      // Allow ±1 day flexibility
      tours = tours
          .where((tour) =>
              (tour.days >= preferredDuration - 1) &&
              (tour.days <= preferredDuration + 1))
          .toList();
    }

    // Filter by travel style
    if (travelStyle != null && travelStyle.isNotEmpty) {
      tours = _filterByTravelStyle(tours, travelStyle);
    }

    // Filter by minimum rating
    if (minRating != null) {
      tours = HardcodedWorldToursDataset.filterByRating(tours, minRating);
    }

    // Sort results
    if (sortByPopularity) {
      tours = HardcodedWorldToursDataset.sortByPopularity(tours);
    } else {
      tours = HardcodedWorldToursDataset.sortByRating(tours);
    }

    return tours;
  }

  /// Get personalized recommendations for first-time user
  static List<TourPackage> getPersonalizedForNewUser({
    required String? homeCountry,
    required List<String> interests, // ['food', 'culture', 'adventure', 'luxury', 'budget']
  }) {
    var recommendations = <TourPackage>[];

    // If user is from Turkey, start with Turkish tours
    if (homeCountry == 'TR' || homeCountry == 'Turkey') {
      recommendations.addAll(
        HardcodedWorldToursDataset.getToursForCountry('TR').take(3),
      );
    }

    // Add trending tours
    final trending = HardcodedWorldToursDataset.getTrendingTours();
    recommendations.addAll(trending.take(5));

    // Add tours based on interests
    for (final interest in interests) {
      final filtered = _filterByTravelStyle(
        HardcodedWorldToursDataset.allTours,
        interest,
      );
      recommendations.addAll(filtered.take(2));
    }

    // Remove duplicates and return top 10
    final seen = <String>{};
    return recommendations
        .where((tour) => seen.add(tour.id))
        .take(10)
        .toList();
  }

  /// Smart recommendations based on what user just viewed
  static List<TourPackage> getSimilarTours(TourPackage viewedTour) {
    return HardcodedWorldToursDataset.allTours
        .where((tour) =>
            tour.id != viewedTour.id &&
            (tour.cityName == viewedTour.cityName ||
                tour.countryCode == viewedTour.countryCode ||
                tour.days == viewedTour.days))
        .toList();
  }

  /// Get trending tours for home screen
  static List<TourPackage> getTrending() {
    return HardcodedWorldToursDataset.getTrendingTours();
  }

  /// Get featured tours (curated selection)
  static List<TourPackage> getFeatured() {
    final featured = [
      'tour_istanbul_001',
      'tour_paris_001',
      'tour_tokyo_001',
      'tour_bali_001',
      'tour_dubai_001',
      'tour_newyork_001',
      'tour_cappadocia_001',
    ];

    return HardcodedWorldToursDataset.allTours
        .where((tour) => featured.contains(tour.id))
        .toList();
  }

  /// Search tours
  static List<TourPackage> search(String query) {
    if (query.isEmpty) return [];
    return HardcodedWorldToursDataset.searchTours(query);
  }

  /// Private helper: Filter by travel style
  static List<TourPackage> _filterByTravelStyle(
    List<TourPackage> tours,
    String style,
  ) {
    switch (style.toLowerCase()) {
      case 'luxury':
        // Tours in premium destinations (Paris, Tokyo, Dubai, NYC)
        return tours
            .where((tour) => [
                  'Paris',
                  'Tokyo',
                  'Dubai',
                  'New York',
                  'Rome',
                  'Barcelona'
                ].contains(tour.cityName))
            .toList();

      case 'budget':
        // Tours with lower ratings tend to be cheaper, or shorter duration
        return tours
            .where((tour) => tour.days <= 3 || tour.ratingCount < 500)
            .toList();

      case 'adventure':
        // Tours with outdoor/activity focus
        return tours
            .where((tour) =>
                tour.title.toLowerCase().contains('adventure') ||
                tour.title.toLowerCase().contains('safari') ||
                tour.title.toLowerCase().contains('trek') ||
                tour.title.toLowerCase().contains('mountain') ||
                tour.title.toLowerCase().contains('balloon'))
            .toList();

      case 'culture':
        // Tours with cultural focus
        return tours
            .where((tour) =>
                tour.title.toLowerCase().contains('culture') ||
                tour.title.toLowerCase().contains('museum') ||
                tour.title.toLowerCase().contains('temple') ||
                tour.title.toLowerCase().contains('historic') ||
                tour.title.toLowerCase().contains('ancient'))
            .toList();

      case 'food':
        // Tours with food focus
        return tours
            .where((tour) =>
                tour.title.toLowerCase().contains('food') ||
                tour.title.toLowerCase().contains('culinary') ||
                tour.title.toLowerCase().contains('cooking') ||
                tour.title.toLowerCase().contains('wine') ||
                tour.title.toLowerCase().contains('street food'))
            .toList();

      default:
        return tours;
    }
  }

  /// Get statistics for analytics
  static Map<String, dynamic> getStatistics() {
    final allTours = HardcodedWorldToursDataset.allTours;
    final countries = HardcodedWorldToursDataset.getAllCountries();
    final cities = HardcodedWorldToursDataset.getAllCities();

    return {
      'totalTours': allTours.length,
      'totalCountries': countries.length,
      'totalCities': cities.length,
      'averageRating':
          allTours.fold<double>(0, (sum, tour) => sum + tour.ratingAverage) /
              allTours.length,
      'totalFavorites':
          allTours.fold<int>(0, (sum, tour) => sum + tour.favoriteCount),
      'mostPopularCity': _getMostCommonCity(allTours),
      'highestRatedTour': _getHighestRatedTour(allTours),
    };
  }

  static String _getMostCommonCity(List<TourPackage> tours) {
    final cityCount = <String, int>{};
    for (final tour in tours) {
      cityCount[tour.cityName] = (cityCount[tour.cityName] ?? 0) + 1;
    }
    var maxCity = '';
    var maxCount = 0;
    cityCount.forEach((city, count) {
      if (count > maxCount) {
        maxCount = count;
        maxCity = city;
      }
    });
    return maxCity;
  }

  static TourPackage? _getHighestRatedTour(List<TourPackage> tours) {
    if (tours.isEmpty) return null;
    return tours.reduce((a, b) =>
        a.ratingAverage > b.ratingAverage ? a : b);
  }
}
