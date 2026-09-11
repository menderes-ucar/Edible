import '../../domain/entities/tour_package.dart';
import '../datasources/tour_local_data_source.dart';
import '../datasources/tour_remote_data_source.dart';

class TourRepository {
  TourRepository({
    TourLocalDataSource local = const TourLocalDataSource(),
    TourRemoteDataSource? remote,
  })  : _local = local,
        _remote = remote ?? TourRemoteDataSource();

  final TourLocalDataSource _local;
  final TourRemoteDataSource _remote;

  Future<List<TourPackage>> getPackages() async {
    final packages = _local.getPackages();
    return Future.wait(packages.map((package) async {
      try {
        final stats = await _remote.summary(package.id);
        return package.copyWithRatings(
          ratingAverage: stats.average,
          ratingCount: stats.count,
          favoriteCount: stats.favoriteCount,
        );
      } catch (_) {
        return package;
      }
    }));
  }

  Future<TourUserState> userState(String id) => _remote.userState(id);
  Future<void> start(String id) => _remote.startTour(id);
  Future<void> complete(String id) => _remote.completeTour(id);
  Future<void> favorite(String id, bool value) => _remote.setFavorite(id, value);
  Future<void> ratePackage(String id, int rating) => _remote.ratePackage(id, rating);
  Future<void> rateStop(String packageId, String stopId, int rating, {required bool completed}) =>
      _remote.rateStop(packageId, stopId, rating, completed: completed);
}
