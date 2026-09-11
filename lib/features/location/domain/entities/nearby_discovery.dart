import '../../../explore/domain/entities/explore_content.dart';

class NearbyDiscovery {
  const NearbyDiscovery({
    required this.content,
    required this.distanceMeters,
  });

  final ExploreContent content;
  final double distanceMeters;

  String get distanceLabel {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }

    final kilometers = distanceMeters / 1000;
    return '${kilometers.toStringAsFixed(kilometers < 10 ? 1 : 0)} km';
  }
}
