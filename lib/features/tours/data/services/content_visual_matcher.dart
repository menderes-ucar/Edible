import 'package:flutter/material.dart';

import '../../domain/entities/tour_package.dart';
import '../../../explore/data/datasources/verified_media_registry.dart';
import '../../../explore/data/datasources/static_image_catalog.dart';

/// Smart system to match images with content types
class ContentVisualMatcher {
  /// Get curated image URL based on content type
  static String getImageForStop(TourStop stop) {
    final staticUrl = StaticImageCatalog.lookup(title: stop.title, category: stop.kind.name);
    final verified = verifiedMediaFor(stop.title);
    return staticUrl ?? verified?.imageUrl ?? '';
  }

  /// Get curated image URL for tour cover
  static String getImageForTour(TourPackage tour) {
    // A tour package itself is not a physical place. The city resolver is
    // responsible for selecting the current city image.
    final staticUrl = StaticImageCatalog.lookup(title: tour.cityName, cityName: tour.cityName);
    final verified = verifiedMediaFor(tour.cityName);
    return staticUrl ?? verified?.imageUrl ?? '';
  }

  /// Get category icon and color based on stop kind
  static (IconData, Color) getCategoryIconAndColor(TourStopKind kind) {
    switch (kind) {
      case TourStopKind.place:
        return (Icons.location_on, Color(0xFF4ECDC4)); // Turquoise
      case TourStopKind.food:
        return (Icons.restaurant, Color(0xFFFFB66D)); // Orange
      case TourStopKind.culture:
        return (Icons.museum, Color(0xFF2ECC71)); // Green
      case TourStopKind.snack:
        return (Icons.local_cafe, Color(0xFF1ABC9C)); // Teal
      case TourStopKind.nature:
        return (Icons.nature, Color(0xFF58D68D)); // Light Green
      case TourStopKind.shopping:
        return (Icons.shopping_bag, Color(0xFFFF9E42)); // Dark Orange
      case TourStopKind.entertainment:
        return (Icons.theater_comedy, Color(0xFF4ECDC4)); // Turquoise
      case TourStopKind.accommodation:
        return (Icons.hotel, Color(0xFFFF9E42)); // Dark Orange
      case TourStopKind.transportation:
        return (Icons.directions_car, Color(0xFF1ABC9C)); // Teal
      case TourStopKind.drink:
        return (Icons.local_bar, Color(0xFFFFB66D)); // Orange
      case TourStopKind.other:
        return (Icons.place, Color(0xFF95A5A6)); // Grey
    }
  }

  /// Suggest best image URL based on stop description and kind
  static String suggestImageUrl(String title, String kind) {
    // Never return a generic stock photo for a specific place. If an exact
    // verified asset exists, use it; otherwise the SmartContentImage resolver
    // must perform the live, location-aware lookup.
    final staticUrl = StaticImageCatalog.lookup(title: title, category: kind);
    final verified = verifiedMediaFor(title);
    return staticUrl ?? verified?.imageUrl ?? '';
  }

  /// Validate image URL and provide fallback
  static String getValidImageUrl(String? imageUrl, {String? fallback}) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return imageUrl;
    }
    // Do not silently substitute an unrelated stock photo. Returning the
    // caller-provided fallback preserves content accuracy.
    return fallback ?? '';
  }

  /// Get appropriate description based on stop kind
  static String getKindDescription(TourStopKind kind) {
    switch (kind) {
      case TourStopKind.place:
        return 'Place to Visit';
      case TourStopKind.food:
        return 'Restaurant/Food';
      case TourStopKind.culture:
        return 'Cultural Site';
      case TourStopKind.snack:
        return 'Street Food/Snack';
      case TourStopKind.nature:
        return 'Nature';
      case TourStopKind.shopping:
        return 'Shopping';
      case TourStopKind.entertainment:
        return 'Entertainment';
      case TourStopKind.accommodation:
        return 'Hotel/Accommodation';
      case TourStopKind.transportation:
        return 'Transportation';
      case TourStopKind.drink:
        return 'Drinks';
      case TourStopKind.other:
        return 'Other';
    }
  }
}
