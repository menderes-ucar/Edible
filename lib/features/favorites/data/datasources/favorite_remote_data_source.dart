import '../../../../core/services/supabase_service.dart';

class FavoritePersistenceException implements Exception {
  const FavoritePersistenceException(this.code);

  final String code;

  @override
  String toString() => 'FavoritePersistenceException($code)';
}

class FavoriteRemoteDataSource {
  Future<Set<String>> getFavoriteIds() async {
    final client = SupabaseService.client;
    if (client == null) {
      throw const FavoritePersistenceException('supabase_not_configured');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw const FavoritePersistenceException('authentication_required');
    }

    final response = await client
        .from('favorites')
        .select('content_id')
        .eq('user_id', user.id);

    return (response as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .map((row) => row['content_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> addFavorite(String contentId) async {
    final client = SupabaseService.client;
    if (client == null) {
      throw const FavoritePersistenceException('supabase_not_configured');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw const FavoritePersistenceException('authentication_required');
    }

    // Favorites references public.contents(id). The app also has a bundled
    // catalog fallback, so verify the canonical DB row exists before insert.
    final canonical = await client
        .from('contents')
        .select('id')
        .eq('id', contentId)
        .maybeSingle();

    if (canonical == null) {
      throw const FavoritePersistenceException(
        'content_not_synced_to_supabase',
      );
    }

    await client.from('favorites').upsert(
      {
        'user_id': user.id,
        'content_id': contentId,
      },
      onConflict: 'user_id,content_id',
    );
  }

  Future<void> removeFavorite(String contentId) async {
    final client = SupabaseService.client;
    if (client == null) {
      throw const FavoritePersistenceException('supabase_not_configured');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw const FavoritePersistenceException('authentication_required');
    }

    await client
        .from('favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('content_id', contentId);
  }
}
