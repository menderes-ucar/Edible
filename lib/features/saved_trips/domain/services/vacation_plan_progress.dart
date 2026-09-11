import '../entities/saved_trip_itinerary.dart';

enum VacationPlanNextAction {
  addDiscoveries,
  buildItinerary,
  continueItinerary,
  reviewPlan,
}

class VacationPlanProgress {
  const VacationPlanProgress({
    required this.savedCount,
    required this.scheduledCount,
    required this.plannedDayCount,
    required this.totalDayCount,
    required this.unresolvedStopCount,
  });

  final int savedCount;
  final int scheduledCount;
  final int plannedDayCount;
  final int totalDayCount;
  final int unresolvedStopCount;

  int get unscheduledCount =>
      (savedCount - scheduledCount).clamp(0, savedCount).toInt();

  double get scheduleRatio {
    if (savedCount <= 0) return 0;
    return (scheduledCount / savedCount).clamp(0, 1);
  }

  double get dayCoverageRatio {
    if (totalDayCount <= 0) return 0;
    return (plannedDayCount / totalDayCount).clamp(0, 1);
  }

  VacationPlanNextAction get nextAction {
    if (savedCount == 0) return VacationPlanNextAction.addDiscoveries;
    if (scheduledCount == 0) return VacationPlanNextAction.buildItinerary;
    if (unscheduledCount > 0 || plannedDayCount < totalDayCount) {
      return VacationPlanNextAction.continueItinerary;
    }
    return VacationPlanNextAction.reviewPlan;
  }

  static VacationPlanProgress from({
    required int savedCount,
    required int totalDayCount,
    required Iterable<SavedTripItineraryStop> stops,
    required int unresolvedStopCount,
  }) {
    final stopList = stops.toList(growable: false);
    final scheduledContentIds = <String>{
      for (final stop in stopList) stop.contentId,
    };
    final plannedDays = <int>{
      for (final stop in stopList)
        if (stop.dayIndex >= 0 && stop.dayIndex < totalDayCount) stop.dayIndex,
    };

    return VacationPlanProgress(
      savedCount: savedCount,
      scheduledCount: scheduledContentIds.length,
      plannedDayCount: plannedDays.length,
      totalDayCount: totalDayCount,
      unresolvedStopCount: unresolvedStopCount,
    );
  }
}
