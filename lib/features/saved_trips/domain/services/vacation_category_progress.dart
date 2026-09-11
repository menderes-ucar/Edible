import '../../../explore/domain/entities/explore_category.dart';
import '../../../explore/domain/entities/explore_content.dart';
import '../entities/saved_trip_itinerary.dart';

class VacationCategoryProgress {
  const VacationCategoryProgress({
    required this.category,
    required this.availableCount,
    required this.savedCount,
    required this.scheduledCount,
  });

  final ExploreCategory category;
  final int availableCount;
  final int savedCount;
  final int scheduledCount;

  int get unscheduledCount =>
      (savedCount - scheduledCount).clamp(0, savedCount).toInt();

  bool get isComplete => savedCount > 0 && unscheduledCount == 0;
}

class VacationCategoryProgressBuilder {
  const VacationCategoryProgressBuilder._();

  static List<VacationCategoryProgress> build({
    required Iterable<ExploreContent> contents,
    required Iterable<String> savedContentIds,
    required Iterable<SavedTripItineraryStop> itineraryStops,
  }) {
    final savedIds = savedContentIds.toSet();
    final scheduledIds =
        itineraryStops.map((stop) => stop.contentId).toSet();

    final result = <VacationCategoryProgress>[];
    for (final category in ExploreCategory.values) {
      final ids = contents
          .where((item) => item.category == category)
          .map((item) => item.id)
          .toSet();
      if (ids.isEmpty) continue;

      final saved = ids.intersection(savedIds);
      final scheduled = saved.intersection(scheduledIds);

      result.add(
        VacationCategoryProgress(
          category: category,
          availableCount: ids.length,
          savedCount: saved.length,
          scheduledCount: scheduled.length,
        ),
      );
    }

    return List<VacationCategoryProgress>.unmodifiable(result);
  }
}
