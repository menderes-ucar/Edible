
import '../../../../core/services/supabase_service.dart';

class PlaceNameTranslationRemoteDataSource {
 const PlaceNameTranslationRemoteDataSource();

 Future<Map<String,String>> cityNames({
  required Iterable<String> cityIds,
  required String locale,
 }) async {
  final client=SupabaseService.client;
  final ids=cityIds.toSet().toList(growable:false);
  if(client==null||ids.isEmpty)return const {};
  final language=locale.toLowerCase().split(RegExp('[-_]')).first;
  final rows=await client.from('city_translations')
    .select('city_id,display_name').eq('locale',language).inFilter('city_id',ids);
  return <String,String>{
   for(final raw in rows)
    raw['city_id'].toString():(raw['display_name']??'').toString(),
  };
 }
}
