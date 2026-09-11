abstract final class AppRoutes {
  static const home = '/';
  static const favorites = '/favorites';
  static const community = '/community';
  static const messages = '/messages';
  static const notifications = '/notifications';
  static const visits = '/visits';
  static const tours = '/tours';
  static const tourDetail = '/tour';
  static const visitedWorldMap = '/visited-world-map';
  static const journeyReplay = '/journey-replay';
  static const passportTimeline = '/passport-timeline';
  static const travelCalendar = '/travel-calendar';
  static const onThisDay = '/on-this-day';
  static const travelStats = '/travel-stats';
  static const travelAchievements = '/travel-achievements';
  static const countryMastery = '/country-mastery';
  static const countryQuests = '/country-quests';
  static const profile = '/profile';
  static const login = '/login';

  static const content = '/content';
  static const country = '/country';
  static const city = '/city';
  static const cityMap = '/city-map';
  static const passport = '/passport';
  static const collections = '/collections';
  static const collectionDetailRoot = '/collection';
  static const cultureGuide = '/culture-guide';
  static const offlinePacks = '/offline-packs';
  static const tripPlanner = '/trip-planner';
  static const travelAssistant = '/travel-assistant';
  static const paywall = '/premium';
  static const arrivalGuide = '/arrival';
  static const travelMemory = '/travel-memory';
  static const travelCardEditor = '/travel-card-editor';
  static const savedTrips = '/trips';
  static const vacationPlanner = '/plan-vacation';
  static const savedTripDetail = '/trip';
  static const savedTripItinerary = '/trip-itinerary';
  static const savedTripItineraryMap = '/trip-itinerary-map';

  static String tourDetailFor(String packageId) =>
      '$tourDetail/${Uri.encodeComponent(packageId)}';

  static String loginFor(String returnLocation) {
    final normalized = returnLocation.trim();
    if (!normalized.startsWith('/') || normalized.startsWith('//')) {
      return login;
    }

    return '$login?from=${Uri.encodeQueryComponent(normalized)}';
  }

  static String contentDetail(String id) => '$content/$id';

  static String collectionDetail(String collectionId) =>
      '$collectionDetailRoot/${Uri.encodeComponent(collectionId)}';

  static String countryDetail(String countryCode) =>
      '$country/${Uri.encodeComponent(countryCode)}';

  static String cityMapFor({
    required String countryCode,
    required String cityName,
    String? contentId,
  }) {
    final query = contentId == null || contentId.trim().isEmpty
        ? ''
        : '?contentId=${Uri.encodeQueryComponent(contentId)}';
    return '$cityMap/${Uri.encodeComponent(countryCode)}/${Uri.encodeComponent(cityName)}$query';
  }

  static String cityDetail({
    required String countryCode,
    required String cityName,
  }) =>
      '$city/${Uri.encodeComponent(countryCode)}/${Uri.encodeComponent(cityName)}';


static String cultureGuideFor({
  required String countryCode,
  required String cityName,
}) =>
    '$cultureGuide/${Uri.encodeComponent(countryCode)}/${Uri.encodeComponent(cityName)}';


static String arrivalGuideFor({
  required String countryCode,
  required String cityName,
}) =>
    '$arrivalGuide/${Uri.encodeComponent(countryCode)}/${Uri.encodeComponent(cityName)}';


static String travelMemoryFor(String travelVisitId) =>
    '$travelMemory/${Uri.encodeComponent(travelVisitId)}';


static String travelCardEditorFor(String travelVisitId) =>
    '$travelCardEditor/${Uri.encodeComponent(travelVisitId)}';


static String savedTripDetailFor(String tripId) =>
    '$savedTripDetail/${Uri.encodeComponent(tripId)}';

static String savedTripsForCity({
  required String countryCode,
  required String countryName,
  required String cityName,
}) =>
    '$savedTrips?countryCode=${Uri.encodeQueryComponent(countryCode)}'
    '&countryName=${Uri.encodeQueryComponent(countryName)}'
    '&city=${Uri.encodeQueryComponent(cityName)}';


static String vacationPlannerFor({
  String? countryCode,
  String? countryName,
  String? cityName,
}) {
  final params = <String, String>{};
  final code = countryCode?.trim() ?? '';
  final country = countryName?.trim() ?? '';
  final city = cityName?.trim() ?? '';

  if (code.isNotEmpty) params['countryCode'] = code;
  if (country.isNotEmpty) params['countryName'] = country;
  if (city.isNotEmpty) params['city'] = city;

  if (params.isEmpty) return vacationPlanner;
  return Uri(path: vacationPlanner, queryParameters: params).toString();
}


static String savedTripItineraryFor(String tripId) =>
    '$savedTripItinerary/${Uri.encodeComponent(tripId)}';


static String savedTripItineraryMapFor({
  required String tripId,
  required int dayIndex,
}) =>
    '$savedTripItineraryMap/${Uri.encodeComponent(tripId)}'
    '?day=$dayIndex';
}
