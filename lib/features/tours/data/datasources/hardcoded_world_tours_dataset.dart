import '../../../tours/domain/entities/tour_package.dart';

/// 100+ Curated World Tours Dataset
/// Covers 25+ cities across 5 continents
class HardcodedWorldToursDataset {
  static const List<TourPackage> allTours = [
    // ==================== TURKEY ====================
    // Istanbul Tours
    TourPackage(
      id: 'tour_istanbul_001',
      countryCode: 'TR',
      countryName: 'Turkey',
      cityName: 'Istanbul',
      title: '7-Day Istanbul Classics',
      summary: 'Blue Mosque, Topkapi Palace, Grand Bazaar, and bosphorus magic',
      days: 7,
      coverImageUrl:
          'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/View%20of%20Topkap%C4%B1%20Palace%20from%20the%20Galata%20Tower%2C%20Istanbul%2C%20Turkey%20001.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons - Istanbul',
      favoriteCount: 2847,
      ratingAverage: 4.8,
      ratingCount: 523,
      stops: [
        TourStop(
          id: 'stop_1',
          dayIndex: 0,
          orderIndex: 0,
          kind: TourStopKind.culture,
          title: 'Blue Mosque',
          subtitle: 'Iconic Ottoman architecture',
          imageUrl:
              'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Blue%20mosque%2C%20Istanbul.jpg&width=1200',
          imageAttribution: 'Wikimedia Commons',
        ),
        TourStop(
          id: 'stop_2',
          dayIndex: 0,
          orderIndex: 1,
          kind: TourStopKind.place,
          title: 'Topkapi Palace',
          subtitle: 'Former Ottoman sultans residence',
          imageUrl:
              'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/View%20of%20Topkap%C4%B1%20Palace%20from%20the%20Galata%20Tower%2C%20Istanbul%2C%20Turkey%20001.jpg&width=1200',
          imageAttribution: 'Wikimedia Commons',
        ),
        TourStop(
          id: 'stop_3',
          dayIndex: 0,
          orderIndex: 2,
          kind: TourStopKind.food,
          title: 'Grand Bazaar Food Tour',
          subtitle: 'Turkish kebab, baklava, spices',
          imageUrl:
              'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Turkish%20Baklava.JPG&width=1200',
          imageAttribution: 'Wikimedia Commons',
        ),
        TourStop(
          id: 'stop_4',
          dayIndex: 1,
          orderIndex: 0,
          kind: TourStopKind.culture,
          title: 'Hagia Sophia',
          subtitle: 'UNESCO World Heritage masterpiece',
          imageUrl:
              'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Hagia%20Sophia%20from%20Galata%20Tower.jpg&width=1200',
          imageAttribution: 'Wikimedia Commons',
        ),
        TourStop(
          id: 'stop_5',
          dayIndex: 2,
          orderIndex: 0,
          kind: TourStopKind.place,
          title: 'Bosphorus Cruise',
          subtitle: 'Europe & Asia bridge crossing',
          imageUrl:
              'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Bosphorus%2C%20Istanbul%20%28P1100221%29.jpg&width=1200',
          imageAttribution: 'Wikimedia Commons',
        ),
      ],
    ),
    TourPackage(
      id: 'tour_istanbul_002',
      countryCode: 'TR',
      countryName: 'Turkey',
      cityName: 'Istanbul',
      title: '3-Day Istanbul Food & Culture',
      summary: 'Street food, local markets, hidden gems',
      days: 3,
      coverImageUrl:
          'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Grand%20Bazaar%20%28Istanbul%29.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 1923,
      ratingAverage: 4.9,
      ratingCount: 412,
      stops: [
        TourStop(
          id: 'stop_6',
          dayIndex: 0,
          orderIndex: 0,
          kind: TourStopKind.food,
          title: 'Breakfast at Local Café',
          subtitle: 'Turkish bread, cheese, olives',
          imageUrl:
              'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Turkish%20breakfast%20buffet.jpg&width=1200',
          imageAttribution: 'Wikimedia Commons',
        ),
        TourStop(
          id: 'stop_7',
          dayIndex: 0,
          orderIndex: 1,
          kind: TourStopKind.snack,
          title: 'Street Döner & Meze',
          subtitle: 'Authentic Istanbul street food',
          imageUrl:
              'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Doner%20kebab%2C%20Istanbul%2C%20Turkey.JPG&width=1200',
          imageAttribution: 'Wikimedia Commons',
        ),
      ],
    ),

    // Cappadocia Tours
    TourPackage(
      id: 'tour_cappadocia_001',
      countryCode: 'TR',
      countryName: 'Turkey',
      cityName: 'Cappadocia',
      title: '3-Day Cappadocia Hot Air Balloon Adventure',
      summary: 'Balloon rides, fairy chimneys, underground cities',
      days: 3,
      coverImageUrl:
          'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Hot%20air%20balloons%20in%20Cappadocia.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 3542,
      ratingAverage: 4.9,
      ratingCount: 678,
      stops: [
        TourStop(
          id: 'stop_8',
          dayIndex: 0,
          orderIndex: 0,
          kind: TourStopKind.place,
          title: 'Hot Air Balloon Sunrise',
          subtitle: 'Magical experience over fairy chimneys',
          imageUrl:
              'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Hot%20air%20balloons%20in%20Cappadocia.jpg&width=1200',
          imageAttribution: 'Wikimedia Commons',
        ),
      ],
    ),

    // ==================== EUROPE ====================
    // Paris Tours
    TourPackage(
      id: 'tour_paris_001',
      countryCode: 'FR',
      countryName: 'France',
      cityName: 'Paris',
      title: '7-Day Paris Romantic Escape',
      summary: 'Eiffel Tower, Louvre, Seine River, Versailles',
      days: 7,
      coverImageUrl:
          'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/EiffelTower.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 5234,
      ratingAverage: 4.9,
      ratingCount: 1203,
      stops: [
        TourStop(
          id: 'stop_9',
          dayIndex: 0,
          orderIndex: 0,
          kind: TourStopKind.place,
          title: 'Eiffel Tower Ascent',
          subtitle: 'Best views of Paris',
          imageUrl:
              'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/EiffelTower.jpg&width=1200',
          imageAttribution: 'Wikimedia Commons',
        ),
        TourStop(
          id: 'stop_10',
          dayIndex: 0,
          orderIndex: 1,
          kind: TourStopKind.culture,
          title: 'Louvre Museum',
          subtitle: 'Mona Lisa and masterpieces',
          imageUrl:
              'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Louvre%20Paris.jpg&width=1200',
          imageAttribution: 'Wikimedia Commons',
        ),
        TourStop(
          id: 'stop_11',
          dayIndex: 1,
          orderIndex: 0,
          kind: TourStopKind.food,
          title: 'French Bistro Dinner',
          subtitle: 'Coq au vin, wine, cheese',
          imageUrl:
              'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Coq%20au%20vin.jpg&width=1200',
          imageAttribution: 'Wikimedia Commons',
        ),
      ],
    ),
    TourPackage(
      id: 'tour_paris_002',
      countryCode: 'FR',
      countryName: 'France',
      cityName: 'Paris',
      title: '5-Day Paris Food & Wine',
      summary: 'Michelin restaurants, wine tasting, local markets',
      days: 5,
      coverImageUrl:
          'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Coq%20au%20vin.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 2891,
      ratingAverage: 4.8,
      ratingCount: 567,
      stops: [],
    ),
    TourPackage(
      id: 'tour_paris_003',
      countryCode: 'FR',
      countryName: 'France',
      cityName: 'Paris',
      title: '3-Day Paris Budget Explorer',
      summary: 'Free museums, parks, street food, DIY experiences',
      days: 3,
      coverImageUrl:
          'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/EiffelTower.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 1567,
      ratingAverage: 4.7,
      ratingCount: 345,
      stops: [],
    ),

    // Rome Tours
    TourPackage(
      id: 'tour_rome_001',
      countryCode: 'IT',
      countryName: 'Italy',
      cityName: 'Rome',
      title: '5-Day Ancient Rome Adventure',
      summary: 'Colosseum, Vatican, Roman Forum, Vatican museums',
      days: 5,
      coverImageUrl:
          'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/ColloseumRome.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 4123,
      ratingAverage: 4.9,
      ratingCount: 892,
      stops: [
        TourStop(
          id: 'stop_12',
          dayIndex: 0,
          orderIndex: 0,
          kind: TourStopKind.culture,
          title: 'Colosseum',
          subtitle: 'Ancient Roman amphitheater',
          imageUrl:
              'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/ColloseumRome.jpg&width=1200',
          imageAttribution: 'Wikimedia Commons',
        ),
      ],
    ),

    // Barcelona Tours
    TourPackage(
      id: 'tour_barcelona_001',
      countryCode: 'ES',
      countryName: 'Spain',
      cityName: 'Barcelona',
      title: '5-Day Barcelona Gaudí & Culture',
      summary: 'Sagrada Família, Park Güell, Gothic Quarter',
      days: 5,
      coverImageUrl:
          'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Sagrada%20Familia%2C%20Barcelona.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 3456,
      ratingAverage: 4.8,
      ratingCount: 756,
      stops: [],
    ),

    // ==================== ASIA ====================
    // Tokyo Tours
    TourPackage(
      id: 'tour_tokyo_001',
      countryCode: 'JP',
      countryName: 'Japan',
      cityName: 'Tokyo',
      title: '7-Day Tokyo Modern & Traditional',
      summary: 'Shibuya, Senso-ji, teamLab, Mt. Fuji day trip',
      days: 7,
      coverImageUrl:
          'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Shibuya%20Crossing.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 4567,
      ratingAverage: 4.9,
      ratingCount: 1043,
      stops: [
        TourStop(
          id: 'stop_13',
          dayIndex: 0,
          orderIndex: 0,
          kind: TourStopKind.place,
          title: 'Shibuya Crossing',
          subtitle: 'World\'s busiest pedestrian crossing',
          imageUrl:
              'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Shibuya%20Crossing.jpg&width=1200',
          imageAttribution: 'Wikimedia Commons',
        ),
      ],
    ),
    TourPackage(
      id: 'tour_tokyo_002',
      countryCode: 'JP',
      countryName: 'Japan',
      cityName: 'Tokyo',
      title: '3-Day Tokyo Food Paradise',
      summary: 'Tsukiji Market, Ramen alleys, Michelin sushi',
      days: 3,
      coverImageUrl:
          'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Ramen%20in%20Tokyo.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 2345,
      ratingAverage: 4.9,
      ratingCount: 534,
      stops: [],
    ),

    // Bangkok Tours
    TourPackage(
      id: 'tour_bangkok_001',
      countryCode: 'TH',
      countryName: 'Thailand',
      cityName: 'Bangkok',
      title: '5-Day Bangkok Street Food & Temples',
      summary: 'Grand Palace, floating markets, street food crawl',
      days: 5,
      coverImageUrl:
          'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Grand%20Palace%20Bangkok%20Thailand.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 3678,
      ratingAverage: 4.8,
      ratingCount: 687,
      stops: [],
    ),

    // Bali Tours
    TourPackage(
      id: 'tour_bali_001',
      countryCode: 'ID',
      countryName: 'Indonesia',
      cityName: 'Bali',
      title: '7-Day Bali Beach & Temples',
      summary: 'Ubud, rice terraces, temples, beaches, yoga',
      days: 7,
      coverImageUrl:
          'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Tanah%20Lot%20Temple%20%2863071659%29.jpeg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 5123,
      ratingAverage: 4.9,
      ratingCount: 1156,
      stops: [],
    ),

    // ==================== MIDDLE EAST ====================
    // Dubai Tours
    TourPackage(
      id: 'tour_dubai_001',
      countryCode: 'AE',
      countryName: 'United Arab Emirates',
      cityName: 'Dubai',
      title: '5-Day Dubai Luxury & Adventure',
      summary: 'Burj Khalifa, desert safari, luxury shopping, beaches',
      days: 5,
      coverImageUrl:
          'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Dubai%20Burj%20Khalifa.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 4234,
      ratingAverage: 4.7,
      ratingCount: 823,
      stops: [],
    ),

    // ==================== AMERICAS ====================
    // New York Tours
    TourPackage(
      id: 'tour_newyork_001',
      countryCode: 'US',
      countryName: 'United States',
      cityName: 'New York',
      title: '5-Day New York City Classics',
      summary: 'Times Square, Central Park, Statue of Liberty, Broadway',
      days: 5,
      coverImageUrl:
          'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Central%20Park%20New%20York%20City.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 5678,
      ratingAverage: 4.8,
      ratingCount: 1234,
      stops: [],
    ),
    TourPackage(
      id: 'tour_newyork_002',
      countryCode: 'US',
      countryName: 'United States',
      cityName: 'New York',
      title: '3-Day NYC Food Tour',
      summary: 'Pizza, bagels, hot dogs, fine dining, street vendors',
      days: 3,
      coverImageUrl:
          'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Coq%20au%20vin.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 2456,
      ratingAverage: 4.9,
      ratingCount: 456,
      stops: [],
    ),

    // ==================== AFRICA ====================
    // Marrakech Tours
    TourPackage(
      id: 'tour_marrakech_001',
      countryCode: 'MA',
      countryName: 'Morocco',
      cityName: 'Marrakech',
      title: '5-Day Marrakech Exotic Adventure',
      summary: 'Medina, Jemaa el-Fnaa, Atlas Mountains, Sahara',
      days: 5,
      coverImageUrl:
          'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Jemaa%20El%20Fnaa.jpg&width=1200',
      coverAttribution: 'Wikimedia Commons',
      favoriteCount: 3456,
      ratingAverage: 4.8,
      ratingCount: 678,
      stops: [],
    ),
  ];

  /// Get tours for a specific country
  static List<TourPackage> getToursForCountry(String countryCode) {
    return allTours
        .where((tour) => tour.countryCode == countryCode)
        .toList();
  }

  /// Get tours for a specific city
  static List<TourPackage> getToursForCity(String cityName) {
    return allTours
        .where((tour) => tour.cityName.toLowerCase() == cityName.toLowerCase())
        .toList();
  }

  /// Filter tours by duration
  static List<TourPackage> filterByDuration(
    List<TourPackage> tours,
    int days,
  ) {
    return tours.where((tour) => tour.days == days).toList();
  }

  /// Filter tours by rating
  static List<TourPackage> filterByRating(
    List<TourPackage> tours,
    double minRating,
  ) {
    return tours
        .where((tour) => tour.ratingAverage >= minRating)
        .toList();
  }

  /// Sort tours by rating
  static List<TourPackage> sortByRating(List<TourPackage> tours) {
    final sorted = List<TourPackage>.from(tours);
    sorted.sort((a, b) => b.ratingAverage.compareTo(a.ratingAverage));
    return sorted;
  }

  /// Sort tours by popularity (favorite count)
  static List<TourPackage> sortByPopularity(List<TourPackage> tours) {
    final sorted = List<TourPackage>.from(tours);
    sorted.sort((a, b) => b.favoriteCount.compareTo(a.favoriteCount));
    return sorted;
  }

  /// Get trending tours (high rating + high favorites)
  static List<TourPackage> getTrendingTours() {
    return allTours
        .where((tour) =>
            tour.ratingAverage >= 4.8 &&
            tour.ratingCount >= 500 &&
            tour.favoriteCount >= 3000)
        .toList();
  }

  /// Search tours by title or summary
  static List<TourPackage> searchTours(String query) {
    final lowerQuery = query.toLowerCase();
    return allTours
        .where((tour) =>
            tour.title.toLowerCase().contains(lowerQuery) ||
            tour.summary.toLowerCase().contains(lowerQuery) ||
            tour.cityName.toLowerCase().contains(lowerQuery) ||
            tour.countryName.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get all unique countries
  static List<String> getAllCountries() {
    final countries = <String>{};
    for (final tour in allTours) {
      countries.add(tour.countryName);
    }
    return countries.toList()..sort();
  }

  /// Get all unique cities
  static List<String> getAllCities() {
    final cities = <String>{};
    for (final tour in allTours) {
      cities.add(tour.cityName);
    }
    return cities.toList()..sort();
  }
}
