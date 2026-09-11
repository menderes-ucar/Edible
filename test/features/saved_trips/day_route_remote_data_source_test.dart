import 'package:edible/features/saved_trips/data/datasources/day_route_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('route datasource returns safe fallback for an empty day', () async {
    const dataSource = DayRouteRemoteDataSource();

    final route = await dataSource.getWalkingRoute(const []);

    expect(route.isRoadRoute, isFalse);
    expect(route.coordinates, isEmpty);
    expect(route.distanceMeters, 0);
    expect(route.durationSeconds, 0);
  });
}
