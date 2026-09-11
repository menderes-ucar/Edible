import '../entities/tour_package.dart';
import '../../data/datasources/hardcoded_world_tours_dataset_complete.dart';

/// Production-ready recommendation engine
class TourRecommendationEngine {
  /// Get filtered recommendations
  static List<TourPackage> getRecommendations({
    String? preferredCountry,
    int? preferredDuration,
    String? travelStyle,
    double? minRating,
    bool sortByPopularity = false,
  }) {
    var tours = HardcodedWorldToursDataset.getAllTours();

    // Filter by country
    if (preferredCountry != null && preferredCountry.isNotEmpty) {
      tours = tours
          .where((tour) => tour.countryName.toLowerCase() == preferredCountry.toLowerCase())
          .toList();
    }

    // Filter by duration (±1 day flexibility)
    if (preferredDuration != null) {
      tours = tours
          .where((tour) =>
              (tour.days >= preferredDuration - 1) && (tour.days <= preferredDuration + 1))
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

  /// Get personalized recommendations for new users
  static List<TourPackage> getPersonalizedForNewUser({
    String? homeCountry,
    List<String>? interests,
  }) {
    var recommendations = <TourPackage>[];

    // Start with home country tours
    if (homeCountry == 'TR' || homeCountry == 'Turkey') {
      recommendations.addAll(HardcodedWorldToursDataset.getToursForCountry('TR').take(3));
    }

    // Add trending tours
    recommendations.addAll(HardcodedWorldToursDataset.getTrendingTours().take(5));

    // Add tours based on interests
    if (interests != null && interests.isNotEmpty) {
      for (final interest in interests) {
        final filtered = _filterByTravelStyle(
          HardcodedWorldToursDataset.getAllTours(),
          interest,
        );
        recommendations.addAll(filtered.take(2));
      }
    }

    // Remove duplicates
    final seen = <String>{};
    return recommendations.where((tour) => seen.add(tour.id)).take(10).toList();
  }

  /// Get similar tours
  static List<TourPackage> getSimilarTours(TourPackage viewedTour) {
    return HardcodedWorldToursDataset.getAllTours()
        .where((tour) =>
            tour.id != viewedTour.id &&
            (tour.cityName == viewedTour.cityName ||
                tour.countryCode == viewedTour.countryCode ||
                tour.days == viewedTour.days))
        .toList();
  }

  /// Get trending tours
  static List<TourPackage> getTrending() {
    return HardcodedWorldToursDataset.getTrendingTours();
  }

  /// Get featured/curated tours
  static List<TourPackage> getFeatured() {
    final featured = [
      'tour_istanbul_001',
      'tour_paris_001',
      'tour_tokyo_001',
      'tour_dubai_001',
      'tour_rome_001',
    ];
    return HardcodedWorldToursDataset.getAllTours()
        .where((tour) => featured.contains(tour.id))
        .toList();
  }

  /// Search tours
  static List<TourPackage> search(String query) {
    if (query.isEmpty) return [];
    return HardcodedWorldToursDataset.searchTours(query);
  }

  /// Filter by travel style
  static List<TourPackage> _filterByTravelStyle(
    List<TourPackage> tours,
    String style,
  ) {
    switch (style.toLowerCase()) {
      case 'luxury':
        return tours
            .where((tour) => ['Paris', 'Tokyo', 'Dubai', 'Rome'].contains(tour.cityName))
            .toList();

      case 'budget':
        return tours.where((tour) => tour.days <= 3).toList();

      case 'adventure':
        return tours
            .where((tour) =>
                tour.title.toLowerCase().contains('adventure') ||
                tour.title.toLowerCase().contains('safari'))
            .toList();

      case 'culture':
        return tours
            .where((tour) =>
                tour.title.toLowerCase().contains('culture') ||
                tour.title.toLowerCase().contains('historic'))
            .toList();

      case 'food':
        return tours
            .where((tour) =>
                tour.title.toLowerCase().contains('food') ||
                tour.summary.toLowerCase().contains('food'))
            .toList();

      default:
        return tours;
    }
  }

  /// Get statistics
  static Map<String, dynamic> getStatistics() {
    final allTours = HardcodedWorldToursDataset.getAllTours();
    return {
      'totalTours': allTours.length,
      'totalCountries': HardcodedWorldToursDataset.getAllCountries().length,
      'totalCities': HardcodedWorldToursDataset.getAllCities().length,
      'averageRating':
          allTours.fold(0.0, (sum, tour) => sum + tour.ratingAverage) / allTours.length,
      'totalFavorites':
          allTours.fold(0, (sum, tour) => sum + tour.favoriteCount),
    };
  }
}
