import '../../../../core/services/supabase_service.dart';

class TourRatingSummary {
  const TourRatingSummary(this.average, this.count, this.favoriteCount);
  final double average;
  final int count;
  final int favoriteCount;
}

class TourUserState {
  const TourUserState({
    this.status,
    this.isFavorite = false,
    this.packageRating,
    this.completedStopIds = const <String>{},
    this.stopRatings = const <String, int>{},
  });
  final String? status;
  final bool isFavorite;
  final int? packageRating;
  final Set<String> completedStopIds;
  final Map<String, int> stopRatings;
}

class TourRemoteDataSource {
  Future<TourRatingSummary> summary(String packageId) async {
    final client = SupabaseService.client;
    if (client == null) return const TourRatingSummary(0, 0, 0);
    final row = await client.from('tour_package_stats').select().eq('package_id', packageId).maybeSingle();
    if (row == null) return const TourRatingSummary(0, 0, 0);
    return TourRatingSummary(
      (row['rating_average'] as num?)?.toDouble() ?? 0,
      (row['rating_count'] as num?)?.toInt() ?? 0,
      (row['favorite_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<TourUserState> userState(String packageId) async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return const TourUserState();
    final packageRow = await client.from('user_tour_packages').select('status').eq('user_id', user.id).eq('package_id', packageId).maybeSingle();
    final favoriteRow = await client.from('tour_package_favorites').select('package_id').eq('user_id', user.id).eq('package_id', packageId).maybeSingle();
    final ratingRow = await client.from('tour_package_ratings').select('rating').eq('user_id', user.id).eq('package_id', packageId).maybeSingle();
    final progressRows = await client.from('tour_stop_progress').select('stop_id,completed,rating').eq('user_id', user.id).eq('package_id', packageId);
    final completed=<String>{}; final ratings=<String,int>{};
    for (final row in progressRows) {
      final id=row['stop_id']?.toString(); if(id==null) continue;
      if(row['completed']==true) completed.add(id);
      final rating=(row['rating'] as num?)?.toInt(); if(rating!=null) ratings[id]=rating;
    }
    return TourUserState(
      status: packageRow?['status']?.toString(),
      isFavorite: favoriteRow != null,
      packageRating: (ratingRow?['rating'] as num?)?.toInt(),
      completedStopIds: completed,
      stopRatings: ratings,
    );
  }

  Future<void> startTour(String packageId) async {
    final client=SupabaseService.client; final user=client?.auth.currentUser;
    if(client==null||user==null) throw StateError('authentication_required');
    await client.from('user_tour_packages').upsert(
      {'user_id':user.id,'package_id':packageId,'status':'active','completed_at':null},
      onConflict:'user_id,package_id');
  }

  Future<void> completeTour(String packageId) async {
    final client=SupabaseService.client; final user=client?.auth.currentUser;
    if(client==null||user==null) throw StateError('authentication_required');
    await client.from('user_tour_packages').upsert(
      {'user_id':user.id,'package_id':packageId,'status':'completed','completed_at':DateTime.now().toUtc().toIso8601String()},
      onConflict:'user_id,package_id');
  }

  Future<void> setFavorite(String packageId,bool value) async {
    final client=SupabaseService.client; final user=client?.auth.currentUser;
    if(client==null||user==null) throw StateError('authentication_required');
    if(value) {
      await client.from('tour_package_favorites').upsert({'user_id':user.id,'package_id':packageId},onConflict:'user_id,package_id');
    } else {
      await client.from('tour_package_favorites').delete().eq('user_id',user.id).eq('package_id',packageId);
    }
  }

  Future<void> ratePackage(String packageId,int rating) async {
    final client=SupabaseService.client; final user=client?.auth.currentUser;
    if(client==null||user==null) throw StateError('authentication_required');
    await client.from('tour_package_ratings').upsert({'user_id':user.id,'package_id':packageId,'rating':rating},onConflict:'user_id,package_id');
  }

  Future<void> rateStop(String packageId,String stopId,int rating,{required bool completed}) async {
    final client=SupabaseService.client; final user=client?.auth.currentUser;
    if(client==null||user==null) throw StateError('authentication_required');
    await client.from('tour_stop_progress').upsert({
      'user_id':user.id,'package_id':packageId,'stop_id':stopId,
      'completed':completed,'rating':rating,'updated_at':DateTime.now().toUtc().toIso8601String(),
    },onConflict:'user_id,package_id,stop_id');
  }
}
