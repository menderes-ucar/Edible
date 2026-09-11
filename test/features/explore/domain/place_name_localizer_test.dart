
import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/explore/domain/services/place_name_localizer.dart';
void main(){
 test('country follows app language',(){
  expect(PlaceNameLocalizer.country('CN','tr','China'),'Çin');
  expect(PlaceNameLocalizer.country('CN','en','中国'),'China');
  expect(PlaceNameLocalizer.country('CN','zh','China'),'中国');
  expect(PlaceNameLocalizer.country('KZ','tr','Kazakhstan'),'Kazakistan');
 });
 test('city prefers requested locale translation',(){
  expect(PlaceNameLocalizer.city(locale:'tr',fallback:'北京',translations:{'tr':'Pekin','en':'Beijing'}),'Pekin');
  expect(PlaceNameLocalizer.city(locale:'en',fallback:'北京',translations:{'en':'Beijing'}),'Beijing');
 });
}
