import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/explore/data/datasources/map_country_city_expansion_74.dart';
void main(){
 test('requested countries are visible in bundled map catalog',(){
  final x=getMapCountryCityExpansion74('tr');
  expect(x.map((e)=>e.countryCode).toSet(),containsAll(<String>{'US','CN','KZ','KG','UZ','SA','JO','QA','OM'}));
 });
 test('US and China are not single-city catalogs',(){
  final x=getMapCountryCityExpansion74('en');
  expect(x.where((e)=>e.countryCode=='US').map((e)=>e.cityName).toSet().length,greaterThanOrEqualTo(30));
  expect(x.where((e)=>e.countryCode=='CN').map((e)=>e.cityName).toSet().length,greaterThanOrEqualTo(30));
 });
 test('Central Asia is present',(){
  final x=getMapCountryCityExpansion74('en');
  for(final cc in ['KZ','KG','UZ']) expect(x.any((e)=>e.countryCode==cc),isTrue);
 });
}
