import 'package:go_router/go_router.dart';

import '../../features/arrival/presentation/pages/arrival_guide_page.dart';
import '../../features/assistant/presentation/pages/travel_assistant_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/culture/presentation/pages/culture_guide_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/explore/domain/entities/explore_content.dart';
import '../../features/explore/presentation/pages/city_detail_page.dart';
import '../../features/explore/presentation/pages/city_map_page.dart';
import '../../features/explore/presentation/pages/content_detail_page.dart';
import '../../features/explore/presentation/pages/country_detail_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/community/presentation/pages/community_page.dart';
import '../../features/messaging/presentation/pages/messages_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/public_profile_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/offline/presentation/pages/offline_city_packs_page.dart';
import '../../features/subscription/presentation/pages/paywall_page.dart';
import '../../features/trip_planner/presentation/pages/trip_planner_page.dart';
import '../../features/tours/presentation/pages/tours_page.dart';
import '../../features/tours/presentation/pages/tour_detail_page.dart';
import '../../features/tours/domain/entities/tour_package.dart';
import '../../features/travel_history/presentation/pages/journey_replay_page.dart';
import '../../features/travel_history/presentation/pages/passport_timeline_page.dart';
import '../../features/travel_history/presentation/pages/travel_calendar_page.dart';
import '../../features/travel_history/presentation/pages/on_this_day_page.dart';
import '../../features/travel_history/presentation/pages/travel_stats_page.dart';
import '../../features/travel_history/presentation/pages/travel_achievements_page.dart';
import '../../features/travel_journal/presentation/pages/travel_memory_page.dart';
import '../../features/travel_share/presentation/pages/travel_card_editor_page.dart';
import '../../features/visits/presentation/pages/country_mastery_page.dart';
import '../../features/visits/presentation/pages/country_quest_page.dart';
import '../../features/visits/presentation/pages/visited_world_map_page.dart';
import '../../features/visits/presentation/pages/visits_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/progress/presentation/pages/collection_detail_page.dart';
import '../../features/progress/presentation/pages/collections_page.dart';
import '../../features/progress/presentation/pages/passport_page.dart';
import '../../features/saved_trips/presentation/pages/saved_trips_page.dart';
import '../../features/saved_trips/presentation/pages/vacation_planner_page.dart';
import '../../features/saved_trips/presentation/pages/saved_trip_workspace_page.dart';
import '../../features/saved_trips/presentation/pages/saved_trip_itinerary_page.dart';
import '../../features/saved_trips/presentation/pages/saved_trip_itinerary_map_page.dart';
import '../widgets/app_shell.dart';
import 'app_routes.dart';
import 'pages/route_error_page.dart';

abstract final class AppRouter {
  static GoRouter create(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: AppRoutes.home,
      refreshListenable: authProvider,
      errorBuilder: (_, state) => RouteErrorPage(error: state.error),
      redirect: (_, state) {
        final location = state.uri.toString();
        final path = state.uri.path;
        final isLogin = path == AppRoutes.login;

        if (authProvider.isGuest && _requiresAuthentication(path)) {
          return AppRoutes.loginFor(location);
        }

        if (authProvider.isAuthenticated && isLogin) {
          return _safeReturnLocation(state.uri.queryParameters['from']);
        }

        return null;
      },
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(
            location: state.uri.path,
            child: child,
          ),
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, __) => const HomePage(),
            ),
            GoRoute(
              path: AppRoutes.favorites,
              builder: (_, __) => const FavoritesPage(),
            ),
            GoRoute(
              path: AppRoutes.community,
              builder: (_, __) => const CommunityPage(),
            ),
            GoRoute(
              path: AppRoutes.messages,
              builder: (_, __) => const MessagesPage(),
            ),
            GoRoute(
              path: AppRoutes.notifications,
              builder: (_, __) => const NotificationsPage(),
            ),
            GoRoute(
              path: '${ChatPage.route}/:userId',
              builder: (_, state) => ChatPage(userId: state.pathParameters['userId']!),
            ),
            GoRoute(
              path: '${PublicProfilePage.routePrefix}/:userId',
              builder: (_, state) => PublicProfilePage(
                userId: state.pathParameters['userId']!,
              ),
            ),
            GoRoute(
              path: AppRoutes.savedTrips,
              builder: (_, state) => SavedTripsPage(
                initialCountryCode: state.uri.queryParameters['countryCode'],
                initialCountryName: state.uri.queryParameters['countryName'],
                initialCityName: state.uri.queryParameters['city'],
              ),
            ),
            GoRoute(
              path: AppRoutes.tours,
              builder: (_, __) => const ToursPage(),
            ),
            GoRoute(
              path: AppRoutes.visits,
              builder: (_, __) => const VisitsPage(),
            ),
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, __) => const ProfilePage(),
            ),
          ],
        ),
        GoRoute(
          name: 'tour-detail',
          path: '${AppRoutes.tourDetail}/:packageId',
          builder: (_, state) => TourDetailPage(
            packageId: Uri.decodeComponent(state.pathParameters['packageId']!),
            initialPackage: state.extra is TourPackage ? state.extra! as TourPackage : null,
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, state) => LoginPage(
            returnLocation: _safeReturnLocation(
              state.uri.queryParameters['from'],
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.passport,
          builder: (_, __) => const PassportPage(),
        ),
        GoRoute(
          path: AppRoutes.visitedWorldMap,
          builder: (_, __) => const VisitedWorldMapPage(),
        ),
        GoRoute(
          path: AppRoutes.journeyReplay,
          builder: (_, __) => const JourneyReplayPage(),
        ),
        GoRoute(
          path: AppRoutes.passportTimeline,
          builder: (_, __) => const PassportTimelinePage(),
        ),
        GoRoute(
          path: AppRoutes.travelCalendar,
          builder: (_, __) => const TravelCalendarPage(),
        ),
        GoRoute(
          path: AppRoutes.onThisDay,
          builder: (_, __) => const OnThisDayPage(),
        ),
        GoRoute(
          path: AppRoutes.travelStats,
          builder: (_, __) => const TravelStatsPage(),
        ),
        GoRoute(
          path: AppRoutes.travelAchievements,
          builder: (_, __) => const TravelAchievementsPage(),
        ),
        GoRoute(
          path: AppRoutes.countryMastery,
          builder: (_, __) => const CountryMasteryPage(),
        ),
        GoRoute(
          path: AppRoutes.countryQuests,
          builder: (_, __) => const CountryQuestPage(),
        ),
        GoRoute(
          path: '${AppRoutes.travelMemory}/:visitId',
          builder: (_, state) => TravelMemoryPage(
            travelVisitId: Uri.decodeComponent(
              state.pathParameters['visitId']!,
            ),
          ),
        ),
        GoRoute(
          path: '${AppRoutes.travelCardEditor}/:visitId',
          builder: (_, state) => TravelCardEditorPage(
            travelVisitId: Uri.decodeComponent(
              state.pathParameters['visitId']!,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.collections,
          builder: (_, __) => const CollectionsPage(),
        ),
        GoRoute(
          path: '${AppRoutes.collectionDetailRoot}/:collectionId',
          builder: (_, state) => CollectionDetailPage(
            collectionId: Uri.decodeComponent(
              state.pathParameters['collectionId']!,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.vacationPlanner,
          builder: (_, state) => VacationPlannerPage(
            initialCountryCode: state.uri.queryParameters['countryCode'],
            initialCountryName: state.uri.queryParameters['countryName'],
            initialCityName: state.uri.queryParameters['city'],
          ),
        ),
        GoRoute(
          path: '${AppRoutes.savedTripDetail}/:tripId',
          builder: (_, state) => SavedTripWorkspacePage(
            tripId: Uri.decodeComponent(
              state.pathParameters['tripId']!,
            ),
          ),
        ),
        GoRoute(
          path: '${AppRoutes.savedTripItinerary}/:tripId',
          builder: (_, state) => SavedTripItineraryPage(
            tripId: Uri.decodeComponent(
              state.pathParameters['tripId']!,
            ),
          ),
        ),
        GoRoute(
          path: '${AppRoutes.savedTripItineraryMap}/:tripId',
          builder: (_, state) {
            final parsedDay = int.tryParse(
                  state.uri.queryParameters['day'] ?? '0',
                ) ??
                0;

            return SavedTripItineraryMapPage(
              tripId: Uri.decodeComponent(
                state.pathParameters['tripId']!,
              ),
              dayIndex: parsedDay < 0 ? 0 : parsedDay,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.offlinePacks,
          builder: (_, __) => const OfflineCityPacksPage(),
        ),
        GoRoute(
          path: AppRoutes.tripPlanner,
          builder: (_, __) => const TripPlannerPage(),
        ),
        GoRoute(
          path: AppRoutes.travelAssistant,
          builder: (_, state) => TravelAssistantPage(
            defaultCityName: state.uri.queryParameters['city'],
          ),
        ),
        GoRoute(
          path: AppRoutes.paywall,
          builder: (_, state) => PaywallPage(
            featureName: state.uri.queryParameters['feature'],
          ),
        ),
        GoRoute(
          path: '${AppRoutes.arrivalGuide}/:countryCode/:cityName',
          builder: (_, state) => ArrivalGuidePage(
            countryCode: Uri.decodeComponent(
              state.pathParameters['countryCode']!,
            ),
            cityName: Uri.decodeComponent(
              state.pathParameters['cityName']!,
            ),
          ),
        ),
        GoRoute(
          path: '${AppRoutes.cultureGuide}/:countryCode/:cityName',
          builder: (_, state) => CultureGuidePage(
            countryCode: Uri.decodeComponent(
              state.pathParameters['countryCode']!,
            ),
            cityName: Uri.decodeComponent(
              state.pathParameters['cityName']!,
            ),
          ),
        ),
        GoRoute(
          path: '${AppRoutes.content}/:id',
          builder: (_, state) => ContentDetailPage(
            contentId: state.pathParameters['id']!,
            initialContent: state.extra is ExploreContent
                ? state.extra! as ExploreContent
                : null,
          ),
        ),
        GoRoute(
          path: '${AppRoutes.country}/:countryCode',
          builder: (_, state) => CountryDetailPage(
            countryCode: Uri.decodeComponent(
              state.pathParameters['countryCode']!,
            ),
          ),
        ),
        GoRoute(
          path: '${AppRoutes.cityMap}/:countryCode/:cityName',
          builder: (_, state) => CityMapPage(
            countryCode: Uri.decodeComponent(state.pathParameters['countryCode']!),
            cityName: Uri.decodeComponent(state.pathParameters['cityName']!),
            focusContentId: state.uri.queryParameters['contentId'],
          ),
        ),
        GoRoute(
          path: '${AppRoutes.city}/:countryCode/:cityName',
          builder: (_, state) => CityDetailPage(
            countryCode: Uri.decodeComponent(
              state.pathParameters['countryCode']!,
            ),
            cityName: Uri.decodeComponent(
              state.pathParameters['cityName']!,
            ),
          ),
        ),
      ],
    );
  }
  static bool _requiresAuthentication(String path) {
    return path == AppRoutes.messages ||
        path == AppRoutes.notifications ||
        path.startsWith('${ChatPage.route}/') ||
        path == AppRoutes.vacationPlanner ||
        path.startsWith('${AppRoutes.savedTripDetail}/') ||
        path.startsWith('${AppRoutes.savedTripItinerary}/') ||
        path.startsWith('${AppRoutes.savedTripItineraryMap}/') ||
        path.startsWith('${AppRoutes.collectionDetailRoot}/') ||
        path.startsWith('${AppRoutes.travelMemory}/') ||
        path.startsWith('${AppRoutes.travelCardEditor}/');
  }

  static String _safeReturnLocation(String? candidate) {
    final value = candidate?.trim() ?? '';
    if (value.isEmpty ||
        !value.startsWith('/') ||
        value.startsWith('//') ||
        value.startsWith(AppRoutes.login)) {
      return AppRoutes.home;
    }

    return value;
  }

}
