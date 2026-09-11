
import '../../../../core/services/supabase_service.dart';

class VerifiedContentMedia {
 const VerifiedContentMedia({
  required this.imageUrl,required this.sourcePageUrl,required this.author,
  required this.licenseName,required this.licenseUrl,required this.attributionRequired,
 });
 final String imageUrl,sourcePageUrl,author,licenseName,licenseUrl;
 final bool attributionRequired;
}

class ContentMediaRemoteDataSource {
 const ContentMediaRemoteDataSource();

 Future<List<VerifiedContentMedia>> forContent(String contentId) async {
  final client=SupabaseService.client;
  if(client==null)return const [];
  final rows=await client.from('content_media').select()
    .eq('content_id',contentId).order('is_primary',ascending:false).limit(8);
  return rows.map<VerifiedContentMedia>((raw){
   final r=Map<String,dynamic>.from(raw);
   return VerifiedContentMedia(
    imageUrl:(r['image_url']??'').toString(),
    sourcePageUrl:(r['source_page_url']??'').toString(),
    author:(r['author']??'').toString(),
    licenseName:(r['license_name']??'').toString(),
    licenseUrl:(r['license_url']??'').toString(),
    attributionRequired:r['attribution_required']!=false,
   );
  }).where((m)=>m.imageUrl.isNotEmpty).toList(growable:false);
 }
}
