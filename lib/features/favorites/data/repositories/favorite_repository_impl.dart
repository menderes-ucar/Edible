import '../../domain/repositories/favorite_repository.dart';
import '../datasources/favorite_remote_data_source.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  FavoriteRepositoryImpl({
    required FavoriteRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final FavoriteRemoteDataSource _remoteDataSource;

  @override
  Future<Set<String>> getFavoriteIds() {
    return _remoteDataSource.getFavoriteIds();
  }

  @override
  Future<void> addFavorite(String contentId) {
    return _remoteDataSource.addFavorite(contentId);
  }

  @override
  Future<void> removeFavorite(String contentId) {
    return _remoteDataSource.removeFavorite(contentId);
  }
}
