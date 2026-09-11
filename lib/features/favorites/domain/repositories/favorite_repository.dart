abstract interface class FavoriteRepository {
  Future<Set<String>> getFavoriteIds();
  Future<void> addFavorite(String contentId);
  Future<void> removeFavorite(String contentId);
}
