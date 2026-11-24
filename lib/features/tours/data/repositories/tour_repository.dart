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

  /// Yerel katalog: ağ beklemeden anında döner.
  List<TourPackage> getLocalPackages() => _local.getPackages();

  /// Yerel katalog + puan/favori sayıları. Tek sorgu, zaman aşımı ve hata
  /// durumunda yerel liste döner (sayfa asla yüklenmiş halde takılmaz).
  Future<List<TourPackage>> getPackages() async {
    final packages = _local.getPackages();
    try {
      final stats =
          await _remote.allSummaries().timeout(const Duration(seconds: 8));
      return packages.map((package) {
        final s = stats[package.id];
        if (s == null) return package;
        return package.copyWithRatings(
          ratingAverage: s.average,
          ratingCount: s.count,
          favoriteCount: s.favoriteCount,
        );
      }).toList();
    } catch (_) {
      return packages;
    }
  }

  Future<TourUserState> userState(String id) => _remote.userState(id);
  Future<void> start(String id) => _remote.startTour(id);
  Future<void> complete(String id) => _remote.completeTour(id);
  Future<void> favorite(String id, bool value) => _remote.setFavorite(id, value);
  Future<void> ratePackage(String id, int rating) => _remote.ratePackage(id, rating);
  Future<void> rateStop(String packageId, String stopId, int rating, {required bool completed}) =>
      _remote.rateStop(packageId, stopId, rating, completed: completed);
}
