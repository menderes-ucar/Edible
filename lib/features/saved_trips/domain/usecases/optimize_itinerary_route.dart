import 'dart:math' as math;

import '../entities/itinerary_route_optimization.dart';
import '../entities/saved_trip_itinerary.dart';

class OptimizeItineraryRoute {
  const OptimizeItineraryRoute();

  ItineraryRouteOptimization call(
    List<SavedTripItineraryStop> stops,
  ) {
    if (stops.length < 3) {
      final distance = _totalDistance(stops);
      return ItineraryRouteOptimization(
        orderedStops: List.unmodifiable(stops),
        distanceBeforeMeters: distance,
        distanceAfterMeters: distance,
      );
    }

    final original = [...stops]
      ..sort((a, b) {
        final byTime = a.startMinute.compareTo(b.startMinute);
        if (byTime != 0) return byTime;
        return a.sortOrder.compareTo(b.sortOrder);
      });

    final distanceBefore = _totalDistance(original);

    // Keep the user's first/earliest stop as an anchor, then choose the
    // geographically nearest unused stop at every step.
    final remaining = original.skip(1).toList();
    final ordered = <SavedTripItineraryStop>[original.first];

    while (remaining.isNotEmpty) {
      final current = ordered.last;
      var nearestIndex = 0;
      var nearestDistance = double.infinity;

      for (var index = 0; index < remaining.length; index++) {
        final distance = _distance(
          current.content.latitude,
          current.content.longitude,
          remaining[index].content.latitude,
          remaining[index].content.longitude,
        );

        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestIndex = index;
        }
      }

      ordered.add(remaining.removeAt(nearestIndex));
    }

    // Small 2-opt pass. With itinerary-sized lists this is inexpensive and
    // fixes common nearest-neighbour crossings/zig-zags.
    var improved = true;
    var iterations = 0;

    while (improved && iterations < 20) {
      improved = false;
      iterations++;

      for (var i = 1; i < ordered.length - 2; i++) {
        for (var k = i + 1; k < ordered.length - 1; k++) {
          final a = ordered[i - 1];
          final b = ordered[i];
          final c = ordered[k];
          final d = ordered[k + 1];

          final current =
              _between(a, b) + _between(c, d);
          final swapped =
              _between(a, c) + _between(b, d);

          if (swapped + 1 < current) {
            final reversed = ordered
                .sublist(i, k + 1)
                .reversed
                .toList(growable: false);

            ordered.replaceRange(i, k + 1, reversed);
            improved = true;
          }
        }
      }
    }

    final distanceAfter = _totalDistance(ordered);

    if (distanceAfter >= distanceBefore) {
      return ItineraryRouteOptimization(
        orderedStops: List.unmodifiable(original),
        distanceBeforeMeters: distanceBefore,
        distanceAfterMeters: distanceBefore,
      );
    }

    return ItineraryRouteOptimization(
      orderedStops: List.unmodifiable(ordered),
      distanceBeforeMeters: distanceBefore,
      distanceAfterMeters: distanceAfter,
    );
  }

  double _totalDistance(
    List<SavedTripItineraryStop> stops,
  ) {
    if (stops.length < 2) return 0;

    var total = 0.0;

    for (var index = 1; index < stops.length; index++) {
      total += _between(stops[index - 1], stops[index]);
    }

    return total;
  }

  double _between(
    SavedTripItineraryStop a,
    SavedTripItineraryStop b,
  ) {
    return _distance(
      a.content.latitude,
      a.content.longitude,
      b.content.latitude,
      b.content.longitude,
    );
  }

  double _distance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;

    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final deltaPhi = (lat2 - lat1) * math.pi / 180;
    final deltaLambda = (lon2 - lon1) * math.pi / 180;

    final a = math.sin(deltaPhi / 2) *
            math.sin(deltaPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(deltaLambda / 2) *
            math.sin(deltaLambda / 2);

    final c = 2 *
        math.atan2(
          math.sqrt(a),
          math.sqrt(1 - a),
        );

    return earthRadiusMeters * c;
  }
}
