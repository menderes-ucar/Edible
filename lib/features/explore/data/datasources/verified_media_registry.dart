class VerifiedMediaAsset {
  const VerifiedMediaAsset({
    required this.contentTitle,
    required this.imageUrl,
    required this.sourcePageUrl,
    required this.author,
    required this.license,
  });
  final String contentTitle;
  final String imageUrl;
  final String sourcePageUrl;
  final String author;
  final String license;

  String get attribution => '$author · $license · Wikimedia Commons';
}

const verifiedMediaRegistry = <String, VerifiedMediaAsset>{

  'Kayseri Castle': VerifiedMediaAsset(
    contentTitle: 'Kayseri Castle',
    imageUrl: 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Kayseri%20Kalesi.jpg&width=1200',
    sourcePageUrl: 'https://commons.wikimedia.org/wiki/File:Kayseri_Kalesi.jpg',
    author: 'Boubacar Amadou Cisse',
    license: 'CC BY-SA 4.0',
  ),
  'Gevher Nesibe Museum': VerifiedMediaAsset(
    contentTitle: 'Gevher Nesibe Museum',
    imageUrl: 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Gevher%20Nesibe%20Medrese%20%28Cifte%20Medrese%29%20DSCF1179.jpg&width=1200',
    sourcePageUrl: 'https://commons.wikimedia.org/wiki/File:Gevher_Nesibe_Medrese_(Cifte_Medrese)_DSCF1179.jpg',
    author: 'R Prazeres',
    license: 'CC BY-SA 4.0',
  ),
  'Hunat Hatun Complex': VerifiedMediaAsset(
    contentTitle: 'Hunat Hatun Complex',
    imageUrl: 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Hunat%20Hatun%20Mosque%2001.jpg&width=1200',
    sourcePageUrl: 'https://commons.wikimedia.org/wiki/File:Hunat_Hatun_Mosque_01.jpg',
    author: 'Bernard Gagnon',
    license: 'CC BY-SA 3.0',
  ),
  'Erciyes Mountain': VerifiedMediaAsset(
    contentTitle: 'Erciyes Mountain',
    imageUrl: 'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Erciyes%20Mountain%20%28Unsplash%29.jpg&width=1200',
    sourcePageUrl: 'https://commons.wikimedia.org/wiki/File:Erciyes_Mountain_(Unsplash).jpg',
    author: 'Mehmet Kürşat Değer',
    license: 'CC0 1.0',
  ),
  'Eiffel Tower': VerifiedMediaAsset(
    contentTitle:'Eiffel Tower',
    imageUrl:'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/EiffelTower.jpg&width=1200',
    sourcePageUrl:'https://commons.wikimedia.org/wiki/File:EiffelTower.jpg',
    author:'Zoryana',
    license:'CC BY-SA 3.0',
  ),
  'Colosseum': VerifiedMediaAsset(
    contentTitle:'Colosseum',
    imageUrl:'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/ColloseumRome.jpg&width=1200',
    sourcePageUrl:'https://commons.wikimedia.org/wiki/File:ColloseumRome.jpg',
    author:'Adri45an',
    license:'CC BY-SA 4.0',
  ),
  'Topkapı Palace': VerifiedMediaAsset(
    contentTitle:'Topkapı Palace',
    imageUrl:'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/View%20of%20Topkap%C4%B1%20Palace%20from%20the%20Galata%20Tower%2C%20Istanbul%2C%20Turkey%20001.jpg&width=1200',
    sourcePageUrl:'https://commons.wikimedia.org/wiki/File:View_of_Topkap%C4%B1_Palace_from_the_Galata_Tower,_Istanbul,_Turkey_001.jpg',
    author:'Moonik',
    license:'CC BY-SA 3.0',
  ),
  'Hagia Sophia': VerifiedMediaAsset(
    contentTitle:'Hagia Sophia',
    imageUrl:'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Hagia%20Sophia%20from%20Galata%20Tower.jpg&width=1200',
    sourcePageUrl:'https://commons.wikimedia.org/wiki/File:Hagia_Sophia_from_Galata_Tower.jpg',
    author:'Vassillis',
    license:'CC BY-SA 3.0',
  ),
  'Blue Mosque': VerifiedMediaAsset(
    contentTitle:'Blue Mosque',
    imageUrl:'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Blue%20mosque%2C%20Istanbul.jpg&width=1200',
    sourcePageUrl:'https://commons.wikimedia.org/wiki/File:Blue_mosque,_Istanbul.jpg',
    author:'Bart Hiddink',
    license:'CC BY 2.0',
  ),
  'Galata Tower': VerifiedMediaAsset(
    contentTitle:'Galata Tower',
    imageUrl:'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/View%20of%20the%20Galata%20Tower%20from%20the%20Bosphorus.jpg&width=1200',
    sourcePageUrl:'https://commons.wikimedia.org/wiki/File:View_of_the_Galata_Tower_from_the_Bosphorus.jpg',
    author:'Yair Haklai',
    license:'CC BY-SA 4.0',
  ),
};

VerifiedMediaAsset? verifiedMediaFor(String title) {
  final direct = verifiedMediaRegistry[title];
  if (direct != null) return direct;

  final normalized = _normalizeMediaTitle(title);
  for (final asset in verifiedMediaRegistry.values) {
    if (_normalizeMediaTitle(asset.contentTitle) == normalized) {
      return asset;
    }
  }
  return null;
}

String _normalizeMediaTitle(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('ı', 'i')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ş', 's')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

