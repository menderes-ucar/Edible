import 'package:flutter_test/flutter_test.dart';

import 'package:edible/features/explore/domain/entities/explore_category.dart';
import 'package:edible/features/explore/domain/entities/explore_content.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';
import 'package:edible/features/saved_trips/domain/entities/saved_trip_itinerary.dart';
import 'package:edible/features/saved_trips/domain/services/vacation_plan_progress.dart';

void main() {
  test('no discoveries points user to discovery', () {
    final progress = VacationPlanProgress.from(
      savedCount: 0,
      totalDayCount: 3,
      stops: const [],
      unresolvedStopCount: 0,
    );
    expect(progress.nextAction, VacationPlanNextAction.addDiscoveries);
  });

  test('saved discoveries without itinerary point to build itinerary', () {
    final progress = VacationPlanProgress.from(
      savedCount: 4,
      totalDayCount: 3,
      stops: const [],
      unresolvedStopCount: 0,
    );
    expect(progress.nextAction, VacationPlanNextAction.buildItinerary);
    expect(progress.unscheduledCount, 4);
  });

  test('partial itinerary exposes scheduled and planned-day progress', () {
    final progress = VacationPlanProgress.from(
      savedCount: 4,
      totalDayCount: 3,
      stops: [_stop('a', 0), _stop('b', 1)],
      unresolvedStopCount: 0,
    );
    expect(progress.scheduledCount, 2);
    expect(progress.plannedDayCount, 2);
    expect(progress.unscheduledCount, 2);
    expect(progress.nextAction, VacationPlanNextAction.continueItinerary);
  });

  test('complete coverage points user to review', () {
    final progress = VacationPlanProgress.from(
      savedCount: 3,
      totalDayCount: 3,
      stops: [_stop('a', 0), _stop('b', 1), _stop('c', 2)],
      unresolvedStopCount: 0,
    );
    expect(progress.nextAction, VacationPlanNextAction.reviewPlan);
    expect(progress.scheduleRatio, 1);
    expect(progress.dayCoverageRatio, 1);
  });
}

SavedTripItineraryStop _stop(String id, int day) {
  return SavedTripItineraryStop(
    id: 'stop-$id',
    tripId: 'trip',
    contentId: id,
    dayIndex: day,
    startMinute: 600,
    sortOrder: 0,
    content: ExploreContent(
      id: id,
      countryCode: 'IT',
      countryName: 'Italy',
      cityName: 'Rome',
      category: ExploreCategory.place,
      title: id,
      shortDescription: '',
      description: '',
      latitude: 41.9,
      longitude: 12.5,
      tags: const [],
      metadata: const ExploreMetadata(),
      galleryImageUrls: const [],
    ),
  );
}
