class ExploreImageAsset {
  const ExploreImageAsset(this.url, this.attribution);
  final String url;
  final String attribution;
}

/// Curated, direct image URLs only. No search-result URL is treated as an image.
const exploreImageRegistry = <String, ExploreImageAsset>{
  'Topkapı Palace': ExploreImageAsset(
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/View%20of%20Topkap%C4%B1%20Palace%20from%20the%20Galata%20Tower%2C%20Istanbul%2C%20Turkey%20001.jpg&width=1200',
    'Moonik · CC BY-SA 3.0 · Wikimedia Commons',
  ),
  'Hagia Sophia': ExploreImageAsset(
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Hagia%20Sophia%20from%20Galata%20Tower.jpg&width=1200',
    'Vassillis · CC BY-SA 3.0 · Wikimedia Commons',
  ),
  'Blue Mosque': ExploreImageAsset(
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Blue%20mosque%2C%20Istanbul.jpg&width=1200',
    'Bart Hiddink · CC BY 2.0 · Wikimedia Commons',
  ),
  'Basilica Cistern': ExploreImageAsset(
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Istanbul%2C%20Basilica%20Cistern.jpg&width=1200',
    'Wikimedia Commons · free-license file',
  ),
  'Galata Tower': ExploreImageAsset(
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/View%20of%20the%20Galata%20Tower%20from%20the%20Bosphorus.jpg&width=1200',
    'Yair Haklai · CC BY-SA 4.0 · Wikimedia Commons',
  ),
  'Dolmabahçe Palace': ExploreImageAsset(
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Dolmabahce%20Palace%20Istanbul.jpg&width=1200',
    'Wikimedia Commons · free-license file',
  ),
  'Rumeli Fortress': ExploreImageAsset(
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Rumeli%20Fortress.jpg&width=1200',
    'Julia Sumangil · Wikimedia Commons free-license file',
  ),
  'Göreme Open Air Museum': ExploreImageAsset(
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Goreme%20Open%20Air%20Museum.jpg&width=1200',
    'Wikimedia Commons · free-license file',
  ),
  'Pamukkale': ExploreImageAsset(
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Pamukkale%20Turkey.jpg&width=1200',
    'Wikimedia Commons · free-license file',
  ),
  'Sümela Monastery': ExploreImageAsset(
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Sumela%20Monastery%2C%20Trabzon.jpg&width=1200',
    'Wikimedia Commons · free-license file',
  ),
  'Göbeklitepe': ExploreImageAsset(
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/G%C3%B6bekli%20Tepe%2C%20Urfa.jpg&width=1200',
    'Wikimedia Commons · free-license file',
  ),
  'Zeugma Mosaic Museum': ExploreImageAsset(
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Zeugma%20Mosaic%20Museum.jpg&width=1200',
    'Wikimedia Commons · free-license file',
  ),
  'Ephesus': ExploreImageAsset(
    'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Library%20of%20Celsus%2C%20Ephesus%2C%20Turkey.jpg&width=1200',
    'Wikimedia Commons · free-license file',
  ),
};
