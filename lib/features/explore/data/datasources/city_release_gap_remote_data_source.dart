
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/city_content_coverage.dart';

class CityReleaseGapRemoteDataSource {
  const CityReleaseGapRemoteDataSource();

  Future<List<CityContentCoverage>> gaps({int limit=200,int offset=0}) async {
    final client=SupabaseService.client;
    if(client==null)return const [];
    final rows=await client.from('city_content_release_gaps').select()
      .range(offset,offset+limit-1);
    return rows.map<CityContentCoverage>((raw){
      final r=Map<String,dynamic>.from(raw);
      int n(String k)=>(r[k] as num?)?.toInt()??0;
      return CityContentCoverage(
        cityId:r['city_id'].toString(),countryCode:r['country_code'].toString(),
        cityName:r['city_name'].toString(),placeCount:n('place_count'),
        foodCount:n('food_count'),drinkCount:n('drink_count'),snackCount:n('snack_count'),
        cultureCount:n('culture_count'),regionalProductCount:n('regional_product_count'),
        isContentReady:r['is_content_ready']==true,
      );
    }).toList(growable:false);
  }
}
