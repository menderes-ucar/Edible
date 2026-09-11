
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/content_rating_summary.dart';

class ContentRatingRemoteDataSource {
 const ContentRatingRemoteDataSource();

 Future<ContentRatingSummary> load(String contentId) async {
  final client=SupabaseService.client;
  if(client==null)return const ContentRatingSummary(average:0,count:0);
  final stat=await client.from('content_rating_stats').select().eq('content_id',contentId).maybeSingle();
  final user=client.auth.currentUser;
  Map<String,dynamic>? mine;
  if(user!=null){
   mine=await client.from('content_ratings').select('rating').eq('user_id',user.id).eq('content_id',contentId).maybeSingle();
  }
  return ContentRatingSummary(
   average:(stat?['rating_average'] as num?)?.toDouble()??0,
   count:(stat?['rating_count'] as num?)?.toInt()??0,
   myRating:(mine?['rating'] as num?)?.toInt());
 }
 Future<void> rate(String contentId,int rating) async {
  final client=SupabaseService.client;final user=client?.auth.currentUser;
  if(client==null||user==null)throw StateError('authentication_required');
  await client.from('content_ratings').upsert({
   'user_id':user.id,'content_id':contentId,'rating':rating,
   'updated_at':DateTime.now().toUtc().toIso8601String(),
  },onConflict:'user_id,content_id');
 }
}
