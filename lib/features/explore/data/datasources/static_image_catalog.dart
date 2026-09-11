/// Release-time image catalogue.
///
/// IMPORTANT: this file intentionally contains only fixed URLs. It never
/// performs a search, API request or image discovery at runtime.
class StaticImageCatalog {
  static const Map<String, String> exact = {
    'Topkapı Palace': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/View%20of%20Topkap%C4%B1%20Palace%20from%20the%20Galata%20Tower%2C%20Istanbul%2C%20Turkey%20001.jpg&width=1200',
    'Hagia Sophia': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Hagia%20Sophia%20from%20Galata%20Tower.jpg&width=1200',
    'Ayasofya': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Hagia%20Sophia%20from%20Galata%20Tower.jpg&width=1200',
    'Blue Mosque': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Blue%20mosque%2C%20Istanbul.jpg&width=1200',
    'Basilica Cistern': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Istanbul%2C%20Basilica%20Cistern.jpg&width=1200',
    'Galata Tower': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/View%20of%20the%20Galata%20Tower%20from%20the%20Bosphorus.jpg&width=1200',
    'Dolmabahçe Palace': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Dolmabahce%20Palace%20Istanbul.jpg&width=1200',
    'Rumeli Fortress': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Rumeli%20Fortress.jpg&width=1200',
    'Göreme Open Air Museum': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Goreme%20Open%20Air%20Museum.jpg&width=1200',
    'Pamukkale': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Pamukkale%20Turkey.jpg&width=1200',
    'Pamukkale travertenleri': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Pamukkale%20Turkey.jpg&width=1200',
    'Sümela Monastery': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Sumela%20Monastery%2C%20Trabzon.jpg&width=1200',
    'Göbeklitepe': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/G%C3%B6bekli%20Tepe%2C%20Urfa.jpg&width=1200',
    'Zeugma Mosaic Museum': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Zeugma%20Mosaic%20Museum.jpg&width=1200',
    'Ephesus': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Library%20of%20Celsus%2C%20Ephesus%2C%20Turkey.jpg&width=1200',
    'Grand Bazaar Food Tour': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Grand%20Bazaar%20%28Istanbul%29.jpg&width=1200',
    'Bosphorus Cruise': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Bosphorus%2C%20Istanbul%20%28P1100221%29.jpg&width=1200',
    'Breakfast at Local Café': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Turkish%20breakfast%20buffet.jpg&width=1200',
    'Street Döner & Meze': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Doner%20kebab%2C%20Istanbul%2C%20Turkey.JPG&width=1200',
    'Hot Air Balloon Sunrise': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Hot%20air%20balloons%20in%20Cappadocia.jpg&width=1200',
    'Eiffel Tower Ascent': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/EiffelTower.jpg&width=1200',
    'Louvre Museum': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Louvre%20Paris.jpg&width=1200',
    'French Bistro Dinner': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Coq%20au%20vin.jpg&width=1200',
    'Colosseum': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/ColloseumRome.jpg&width=1200',
    'Shibuya Crossing': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Shibuya%20Crossing.jpg&width=1200',
    'Burj Khalifa': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Dubai%20Burj%20Khalifa.jpg&width=1200',
    'Sagrada Familia': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Sagrada%20Familia%2C%20Barcelona.jpg&width=1200',
    'Tanah Lot Temple': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Tanah%20Lot%20Temple%20%2863071659%29.jpeg&width=1200',
    'Jemaa el-Fnaa': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Jemaa%20El%20Fnaa.jpg&width=1200',
    'Kayseri Kalesi': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Kayseri%20Kalesi.jpg&width=1200',
    'Kayseri Castle': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Kayseri%20Kalesi.jpg&width=1200',
    'Gevher Nesibe Museum': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Gevher%20Nesibe%20Medrese%20%28Cifte%20Medrese%29%20DSCF1179.jpg&width=1200',
    'Hunat Hatun Complex': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Hunat%20Hatun%20Mosque%2001.jpg&width=1200',
    'Erciyes Mountain': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Erciyes%20Mountain%20%28Unsplash%29.jpg&width=1200',
    'Eiffel Tower': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/EiffelTower.jpg&width=1200',
    'Koutoubia Mosque': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Koutoubia%20Mosque.jpg&width=1200',
    'Brandenburg Gate': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Brandenburger%20Tor.jpg&width=1200',
    'Brooklyn Bridge': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Brooklyn%20Bridge%20New%20York%20City.jpg&width=1200',
    'Empire State Building': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Empire%20State%20Building%20from%20the%20ground.jpg&width=1200',
    'Central Park': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Central%20Park%20New%20York%20City.jpg&width=1200',
    'Golden Gate Bridge': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Golden%20Gate%20Bridge.jpg&width=1200',
    'Cologne Cathedral': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Cologne%20Cathedral.jpg&width=1200',
    'Rijksmuseum': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Rijksmuseum%20Amsterdam%20Ca.jpg&width=1200',
    'Notre-Dame de Paris': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Notre%20Dame%20de%20Paris%20Wikimedia%20Commons.jpg&width=1200',
    'Musée d’Orsay': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Musee%20d%27Orsay%20Paris.jpg&width=1200',
    'Musée d\'Orsay': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Musee%20d%27Orsay%20Paris.jpg&width=1200',
    'Arc de Triomphe': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Arc%20de%20Triomphe%20Paris.jpg&width=1200',
    'Acropolis': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Acropolis%20of%20Athens.jpg&width=1200',
    'Acropolis of Athens': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Acropolis%20of%20Athens.jpg&width=1200',
    'Acropolis Museum': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Acropolis%20Museum%20Athens.jpg&width=1200',
    'Forbidden City': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Forbidden%20City%20Beijing.jpg&width=1200',
    'Temple of Heaven': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Temple%20of%20Heaven%20Beijing.jpg&width=1200',
    'Summer Palace Beijing': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Summer%20Palace%20Beijing.jpg&width=1200',
    'National Museum of China': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/National%20Museum%20of%20China.jpg&width=1200',
    'Lama Temple Beijing': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Lama%20Temple%20Beijing.jpg&width=1200',
    'Cheonggyecheon Stream': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Cheonggyecheon%20stream%20Seoul.jpg&width=1200',
    'Gyeongbokgung': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Gyeongbokgung%20Palace%20Seoul.jpg&width=1200',
    'Changdeokgung': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Changdeokgung%20Palace%20Seoul.jpg&width=1200',
    'Bukchon Hanok Village': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Bukchon%20Hanok%20Village%20Seoul.jpg&width=1200',
    'Ho Chi Minh Mausoleum': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Ho%20Chi%20Minh%20Mausoleum.jpg&width=1200',
    'Hoàn Kiếm Lake': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Hoan%20Kiem%20Lake%20Hanoi.jpg&width=1200',
    'Temple of Literature': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Temple%20of%20Literature%20Hanoi.jpg&width=1200',
    'Thăng Long Imperial Citadel': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Thang%20Long%20Imperial%20Citadel.jpg&width=1200',
    'Ben Youssef Madrasa': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Ben%20Youssef%20Madrasa.jpg&width=1200',
    'El Badi Palace': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/El%20Badi%20Palace%20Marrakesh.jpg&width=1200',
    'Bahia Palace': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Bahia%20Palace%20Marrakesh.jpg&width=1200',
    'Frida Kahlo Museum': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Frida%20Kahlo%20Museum%20Mexico%20City.jpg&width=1200',
    'Chapultepec Castle': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Chapultepec%20Castle%20Mexico%20City.jpg&width=1200',
    'Alcatraz Island': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Alcatraz%20Island%20San%20Francisco.jpg&width=1200',
    'Art Institute of Chicago': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Art%20Institute%20of%20Chicago.jpg&width=1200',
    'Getty Center': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Getty%20Center%20Los%20Angeles.jpg&width=1200',
    'Griffith Observatory': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Griffith%20Observatory%20Los%20Angeles.jpg&width=1200',
    'High Line': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/High%20Line%20New%20York.jpg&width=1200',
    'Grand Central Terminal': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Grand%20Central%20Terminal.jpg&width=1200',
    'Vatican Museums': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Vatican%20Museums%20%E2%80%A2%20Musei%20Vaticani%20%2846799988891%29.jpg&width=1200',
    'Senso-ji Temple': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Senso-ji.jpg&width=1200',
    'Times Square': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Times%20Square%2C%20New%20York.jpg&width=1200',
    'Desert Safari': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/DUBAI%20DESERT%20SAFARI.jpg&width=1200',
    'Ubud Rice Terraces': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Ubud%20Rice%20Fields.jpg&width=1200',
    'NYC Pizza & Hot Dogs': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/New%20York-Style%20Pizza.png&width=1200',
    'Floating Market Food Tour': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Damnoen%20Saduak%20floating%20market.jpg&width=1200',
  };

  static const Map<String, String> city = {
    // City cards intentionally use a real landmark/photo from that city.
    'Amsterdam': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Amsterdam%20-%20Rijksmuseum.jpg&width=1200',
    'Beijing': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/The%20forbidden%20city%2C%20Beijing.jpg&width=1200',
    'Lisbon': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Bel%C3%A9m%20Tower%20Lisboa.jpg&width=1200',
    'Mexico City': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/National%20Museum%20of%20Anthropology%20Mexico%20City.jpg&width=1200',
    'Bogotá': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/N6%20piece%20from%20gold%20museum%20Bogota.jpg&width=1200',
    'Santiago': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/La%20Moneda%20Palace%20Santiago%20Chile.jpg&width=1200',
    'Dublin': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Trinity%20College%20Dublin%20Ireland.JPG&width=1200',
    'Sydney': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Sydney%20Opera%20House.jpg&width=1200',
    'Helsinki': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Helsinki%20Cathedral.jpg&width=1200',
    'Delhi': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Delhi%20red%20fort.jpg&width=1200',
    'Oslo': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Vikingskipmuseet%20oslo.jpg&width=1200',
    'Auckland': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Auckland%20War%20Memorial%20Museum.jpg&width=1200',
    'Lima': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Larco%20Museum%2C%20Lima%2C%20Peru.jpg&width=1200',
    'Krakow': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Wawel%20Castle.jpg&width=1200',
    'Stockholm': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Vasa%20museum%20Stockholm.jpg&width=1200',
    'Hanoi': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Hoan%20Kiem%20Lake.jpg&width=1200',
    'Buenos Aires': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Teatro%20Col%C3%B3n%20.jpg&width=1200',
    'Brussels': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Grand-Place%20%28Brussels%29%20-%20View%20of%20the%20Brussels%20Town%20Hall%20and%20adjacent%20Baroque%20guildhouses.jpg&width=1200',
    'Rio de Janeiro': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Christ%20the%20Redeemer%20at%20Rio.jpg&width=1200',
    'Toronto': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/CN%20Tower%20Toronto.jpg&width=1200',
    'Budapest': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Hungarian%20Parliament%20Building.jpg&width=1200',
    'Copenhagen': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Rosenborg%20Castle.jpg&width=1200',
    'Vienna': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Sch%C3%B6nbrunn%20Palace.jpg&width=1200',
    'Zurich': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Lake%20Zurich.jpg&width=1200',
    'Prague': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/PragueCastle.jpg&width=1200',
    'Berlin': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Brandenburg%20Gate.jpg&width=1200',
    'Cairo': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/The%20pyramids%20of%20Giza.jpg&width=1200',
    'Barcelona': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Sagrada%20fam%C3%ADlia.jpg&width=1200',
    'London': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Tower%20Of%20London.jpg&width=1200',
    'Athens': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Acropolis%20of%20Athens.jpg&width=1200',
    'Seoul': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Korea%20gyeongbokgung.jpg&width=1200',
    'Istanbul': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/View%20of%20Topkap%C4%B1%20Palace%20from%20the%20Galata%20Tower%2C%20Istanbul%2C%20Turkey%20001.jpg&width=1200',
    'Cappadocia': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Hot%20air%20balloons%20in%20Cappadocia.jpg&width=1200',
    'Paris': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/EiffelTower.jpg&width=1200',
    'Rome': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/ColloseumRome.jpg&width=1200',
    'Tokyo': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Shibuya%20Crossing.jpg&width=1200',
    'Bangkok': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Grand%20Palace%20Bangkok%20Thailand.jpg&width=1200',
    'Bali': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Tanah%20Lot%20Temple%20%2863071659%29.jpeg&width=1200',
    'Dubai': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Dubai%20Burj%20Khalifa.jpg&width=1200',
    'New York': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Central%20Park%20New%20York%20City.jpg&width=1200',
    'Marrakech': 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Jemaa%20El%20Fnaa.jpg&width=1200',
  };

  static const List<String> food = [
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Turkish%20breakfast%20%2820658662572%29.jpg&width=1200',
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Doner%20kebab%2C%20Istanbul%2C%20Turkey.JPG&width=1200',
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Turkish%20Meze%20Plate.jpg&width=1200',
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Turkish%20Baklava.JPG&width=1200',
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/20251213%20Kayseri%20mant%C4%B1s%C4%B1.jpg&width=1200',
  ];

  static const List<String> nature = [
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Pamukkale%20Turkey.jpg&width=1200',
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Hot%20air%20balloons%20in%20Cappadocia.jpg&width=1200',
  ];

  static const List<String> fruit = [
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Apple%20fruit.jpg&width=1200',
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Mango%20fruit.jpg&width=1200',
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Apricot%20fruit.jpg&width=1200',
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Grape%20fruits.jpg&width=1200',
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Kiwi%20fruit.jpg&width=1200',
  ];

  static const List<String> snack = [
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Turkish%20Baklava.JPG&width=1200',
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Croissant.jpg&width=1200',
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Pretzel.jpg&width=1200',
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Macaron.jpg&width=1200',
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Baklava%20et%20al.jpg&width=1200',
  ];

  static const List<String> drink = [
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Melange.jpg&width=1200',
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Turkish%20tea.jpg&width=1200',
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/COFFEE.jpg&width=1200',
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Hot%20Chocolate.jpg&width=1200',
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Cup%20Coffee.jpg&width=1200',
  ];

  static String _normalize(String value) => value.trim().toLowerCase()
      .replaceAll('ı', 'i').replaceAll('İ', 'i').replaceAll('ğ', 'g')
      .replaceAll('ü', 'u').replaceAll('ş', 's').replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Exact-match fallback only.
  ///
  /// Category lists are intentionally NOT consulted here. A food item must
  /// never receive an unrelated food photo, and a city must never receive a
  /// random landmark. Release-time generated records are responsible for full
  /// catalogue coverage.
  static String? lookup({required String title, String? cityName, String? category}) {
    final wanted = _normalize(title);
    if (wanted.isEmpty) return null;

    for (final e in exact.entries) {
      if (_normalize(e.key) == wanted) return e.value;
    }
    return null;
  }

}
