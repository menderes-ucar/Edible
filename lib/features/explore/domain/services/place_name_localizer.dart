
class PlaceNameLocalizer {
  const PlaceNameLocalizer._();

  static const _countries = <String, Map<String,String>>{
    'US': {'en':'United States','tr':'Amerika Birleşik Devletleri','de':'Vereinigte Staaten','fr':'États-Unis','es':'Estados Unidos','it':'Stati Uniti','ar':'الولايات المتحدة','zh':'美国','ko':'미국','ja':'アメリカ合衆国','ru':'США'},
    'CN': {'en':'China','tr':'Çin','de':'China','fr':'Chine','es':'China','it':'Cina','ar':'الصين','zh':'中国','ko':'중국','ja':'中国','ru':'Китай'},
    'KZ': {'en':'Kazakhstan','tr':'Kazakistan','de':'Kasachstan','fr':'Kazakhstan','es':'Kazajistán','it':'Kazakistan','ar':'كازاخستان','zh':'哈萨克斯坦','ko':'카자흐스탄','ja':'カザフスタン','ru':'Казахстан'},
    'KG': {'en':'Kyrgyzstan','tr':'Kırgızistan','de':'Kirgisistan','fr':'Kirghizistan','es':'Kirguistán','it':'Kirghizistan','ar':'قيرغيزستان','zh':'吉尔吉斯斯坦','ko':'키르기스스탄','ja':'キルギス','ru':'Кыргызстан'},
    'UZ': {'en':'Uzbekistan','tr':'Özbekistan','de':'Usbekistan','fr':'Ouzbékistan','es':'Uzbekistán','it':'Uzbekistan','ar':'أوزبكستان','zh':'乌兹别克斯坦','ko':'우즈베키스탄','ja':'ウズベキスタン','ru':'Узбекистан'},
    'SA': {'en':'Saudi Arabia','tr':'Suudi Arabistan','de':'Saudi-Arabien','fr':'Arabie saoudite','es':'Arabia Saudita','it':'Arabia Saudita','ar':'السعودية','zh':'沙特阿拉伯','ko':'사우디아라비아','ja':'サウジアラビア','ru':'Саудовская Аравия'},
    'JO': {'en':'Jordan','tr':'Ürdün','de':'Jordanien','fr':'Jordanie','es':'Jordania','it':'Giordania','ar':'الأردن','zh':'约旦','ko':'요르단','ja':'ヨルダン','ru':'Иордания'},
    'QA': {'en':'Qatar','tr':'Katar','de':'Katar','fr':'Qatar','es':'Catar','it':'Qatar','ar':'قطر','zh':'卡塔尔','ko':'카타르','ja':'カタール','ru':'Катар'},
    'OM': {'en':'Oman','tr':'Umman','de':'Oman','fr':'Oman','es':'Omán','it':'Oman','ar':'عُمان','zh':'阿曼','ko':'오만','ja':'オマーン','ru':'Оман'},
  };

  static String country(String code,String locale,String fallback){
    final l=_lang(locale); final names=_countries[code.toUpperCase()];
    return names?[l] ?? names?['en'] ?? fallback;
  }

  /// City translations supplied by Supabase/GeoNames should be passed in [translations].
  /// We never display an unrelated native-script name when a requested-language value exists.
  static String city({
    required String locale,
    required String fallback,
    Map<String,String> translations=const {},
    String? asciiName,
  }){
    final l=_lang(locale);
    final localized=translations[l]?.trim();
    if(localized!=null && localized.isNotEmpty)return localized;
    if(l=='en'){
      final ascii=asciiName?.trim();
      if(ascii!=null && ascii.isNotEmpty)return ascii;
    }
    return fallback;
  }

  static String _lang(String raw)=>raw.trim().toLowerCase().split(RegExp('[-_]')).first;
}
