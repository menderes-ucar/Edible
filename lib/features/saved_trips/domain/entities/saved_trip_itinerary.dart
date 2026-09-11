import '../../../explore/domain/entities/explore_content.dart';

class SavedTripItineraryStop {
  const SavedTripItineraryStop({
    required this.id,
    required this.tripId,
    required this.contentId,
    required this.dayIndex,
    required this.startMinute,
    required this.sortOrder,
    required this.content,
  });

  final String id;
  final String tripId;
  final String contentId;

  /// Zero-based day index inside the SavedTrip date range.
  final int dayIndex;

  /// Minutes after midnight, e.g. 9:30 = 570.
  final int startMinute;

  final int sortOrder;
  final ExploreContent content;

  String get timeLabel {
    final hour = startMinute ~/ 60;
    final minute = startMinute % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }
}

class GeneratedItineraryStop {
  const GeneratedItineraryStop({
    required this.contentId,
    required this.dayIndex,
    required this.startMinute,
    required this.sortOrder,
  });

  final String contentId;
  final int dayIndex;
  final int startMinute;
  final int sortOrder;
}
