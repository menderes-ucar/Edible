import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/services/location_service.dart';
import 'core/theme/app_theme.dart';
import 'features/arrival/data/datasources/arrival_guide_local_data_source.dart';
import 'features/arrival/data/datasources/arrival_guide_remote_data_source.dart';
import 'features/arrival/data/repositories/arrival_guide_repository_impl.dart';
import 'features/arrival/domain/repositories/arrival_guide_repository.dart';
import 'features/arrival/presentation/providers/arrival_guide_provider.dart';
import 'features/arrival_detection/data/datasources/arrival_detection_local_data_source.dart';
import 'features/arrival_detection/data/repositories/arrival_detection_repository_impl.dart';
import 'features/arrival_detection/domain/repositories/arrival_detection_repository.dart';
import 'features/arrival_detection/domain/usecases/detect_arrival.dart';
import 'features/arrival_detection/presentation/providers/arrival_detection_provider.dart';
import 'features/assistant/data/datasources/travel_assistant_local_data_source.dart';
import 'features/assistant/data/repositories/travel_assistant_repository_impl.dart';
import 'features/assistant/domain/repositories/travel_assistant_repository.dart';
import 'features/assistant/presentation/providers/travel_assistant_provider.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/culture/data/datasources/culture_local_data_source.dart';
import 'features/culture/data/datasources/culture_remote_data_source.dart';
import 'features/culture/data/repositories/culture_repository_impl.dart';
import 'features/culture/domain/repositories/culture_repository.dart';
import 'features/culture/presentation/providers/culture_guide_provider.dart';
import 'features/explore/data/datasources/explore_local_data_source.dart';
import 'features/explore/data/datasources/explore_remote_data_source.dart';
import 'features/explore/data/repositories/explore_repository_impl.dart';
import 'features/explore/domain/repositories/explore_repository.dart';
import 'features/favorites/data/datasources/favorite_remote_data_source.dart';
import 'features/favorites/data/repositories/favorite_repository_impl.dart';
import 'features/favorites/domain/repositories/favorite_repository.dart';
import 'features/favorites/presentation/providers/favorites_provider.dart';
import 'features/food/data/datasources/food_local_data_source.dart';
import 'features/food/data/datasources/food_remote_data_source.dart';
import 'features/food/data/repositories/food_repository_impl.dart';
import 'features/food/domain/repositories/food_repository.dart';
import 'features/food/presentation/providers/food_filter_provider.dart';
import 'features/location/domain/usecases/find_nearby_discoveries.dart';
import 'features/location/presentation/providers/location_provider.dart';
import 'features/location/presentation/providers/nearby_provider.dart';
import 'features/offline/data/datasources/offline_city_pack_local_data_source.dart';
import 'features/offline/data/repositories/offline_city_pack_repository_impl.dart';
import 'features/offline/domain/repositories/offline_city_pack_repository.dart';
import 'features/offline/presentation/providers/offline_city_pack_provider.dart';
import 'features/progress/data/datasources/progress_remote_data_source.dart';
import 'features/progress/data/repositories/progress_repository_impl.dart';
import 'features/progress/domain/repositories/progress_repository.dart';
import 'features/progress/presentation/providers/progress_provider.dart';
import 'features/saved_trips/data/datasources/day_route_remote_data_source.dart';
import 'features/saved_trips/data/datasources/saved_trip_itinerary_remote_data_source.dart';
import 'features/saved_trips/data/datasources/saved_trip_remote_data_source.dart';
import 'features/saved_trips/data/repositories/day_route_repository_impl.dart';
import 'features/saved_trips/data/repositories/saved_trip_itinerary_repository_impl.dart';
import 'features/saved_trips/data/repositories/saved_trip_repository_impl.dart';
import 'features/saved_trips/domain/repositories/day_route_repository.dart';
import 'features/saved_trips/domain/repositories/saved_trip_itinerary_repository.dart';
import 'features/saved_trips/domain/repositories/saved_trip_repository.dart';
import 'features/saved_trips/presentation/providers/day_route_provider.dart';
import 'features/saved_trips/presentation/providers/saved_trip_itinerary_provider.dart';
import 'features/saved_trips/presentation/providers/saved_trips_provider.dart';
import 'features/settings/presentation/providers/locale_provider.dart';
import 'features/subscription/data/datasources/subscription_remote_data_source.dart';
import 'features/subscription/data/repositories/purchase_repository_impl.dart';
import 'features/subscription/data/repositories/subscription_repository_impl.dart';
import 'features/subscription/data/services/revenuecat_service.dart';
import 'features/subscription/domain/repositories/purchase_repository.dart';
import 'features/subscription/domain/repositories/subscription_repository.dart';
import 'features/subscription/presentation/providers/purchase_provider.dart';
import 'features/subscription/presentation/providers/subscription_provider.dart';
import 'features/travel_history/data/datasources/travel_history_local_data_source.dart';
import 'features/travel_history/data/datasources/travel_history_remote_data_source.dart';
import 'features/travel_history/data/repositories/travel_history_repository_impl.dart';
import 'features/travel_history/domain/repositories/travel_history_repository.dart';
import 'features/travel_history/presentation/providers/travel_history_provider.dart';
import 'features/travel_journal/data/datasources/travel_journal_remote_data_source.dart';
import 'features/travel_journal/data/repositories/travel_journal_repository_impl.dart';
import 'features/travel_journal/domain/repositories/travel_journal_repository.dart';
import 'features/travel_journal/presentation/providers/travel_memory_provider.dart';
import 'features/trip_planner/presentation/providers/trip_planner_provider.dart';
import 'features/visits/data/datasources/visits_remote_data_source.dart';
import 'features/visits/data/repositories/visits_repository_impl.dart';
import 'features/visits/domain/repositories/visits_repository.dart';
import 'features/visits/presentation/providers/visits_provider.dart';

class EdibleApp extends StatelessWidget {
  const EdibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // IMPORTANT: Provider order is dependency order. A provider may read
        // only dependencies declared above it in this MultiProvider tree.
        Provider<RevenueCatService>(
          create: (_) => RevenueCatService(),
        ),
        Provider<OfflineCityPackLocalDataSource>(
          create: (_) => const OfflineCityPackLocalDataSource(),
        ),
        Provider<ArrivalDetectionRepository>(
          create: (_) => const ArrivalDetectionRepositoryImpl(
            localDataSource: ArrivalDetectionLocalDataSource(),
          ),
        ),
        Provider<ArrivalGuideRepository>(
          create: (_) => ArrivalGuideRepositoryImpl(
            remoteDataSource: ArrivalGuideRemoteDataSource(),
            localDataSource: const ArrivalGuideLocalDataSource(),
          ),
        ),
        Provider<SubscriptionRepository>(
          create: (context) => SubscriptionRepositoryImpl(
            remoteDataSource: SubscriptionRemoteDataSource(),
            revenueCatService: context.read<RevenueCatService>(),
          ),
        ),
        Provider<PurchaseRepository>(
          create: (context) => PurchaseRepositoryImpl(
            revenueCatService: context.read<RevenueCatService>(),
          ),
        ),
        Provider<AuthRepository>(
          create: (_) => AuthRepositoryImpl(
            remoteDataSource: AuthRemoteDataSource(),
          ),
        ),
        Provider<ExploreRepository>(
          create: (context) => ExploreRepositoryImpl(
            remoteDataSource: ExploreRemoteDataSource(),
            localDataSource: ExploreLocalDataSource(),
            offlineDataSource: context.read<OfflineCityPackLocalDataSource>(),
          ),
        ),
        Provider<FavoriteRepository>(
          create: (_) => FavoriteRepositoryImpl(
            remoteDataSource: FavoriteRemoteDataSource(),
          ),
        ),
        Provider<CultureRepository>(
          create: (context) => CultureRepositoryImpl(
            remoteDataSource: CultureRemoteDataSource(),
            localDataSource: const CultureLocalDataSource(),
            offlineDataSource: context.read<OfflineCityPackLocalDataSource>(),
          ),
        ),
        Provider<FoodRepository>(
          create: (context) => FoodRepositoryImpl(
            remoteDataSource: FoodRemoteDataSource(),
            localDataSource: const FoodLocalDataSource(),
            offlineDataSource: context.read<OfflineCityPackLocalDataSource>(),
          ),
        ),
        Provider<TravelAssistantRepository>(
          create: (context) => TravelAssistantRepositoryImpl(
            localDataSource: TravelAssistantLocalDataSource(
              exploreRepository: context.read<ExploreRepository>(),
              foodRepository: context.read<FoodRepository>(),
              cultureRepository: context.read<CultureRepository>(),
            ),
          ),
        ),
        Provider<TravelJournalRepository>(
          create: (_) => TravelJournalRepositoryImpl(
            remoteDataSource: TravelJournalRemoteDataSource(),
          ),
        ),
        Provider<TravelHistoryRepository>(
          create: (_) => TravelHistoryRepositoryImpl(
            remoteDataSource: TravelHistoryRemoteDataSource(),
            localDataSource: const TravelHistoryLocalDataSource(),
          ),
        ),
        Provider<VisitsRepository>(
          create: (_) => VisitsRepositoryImpl(
            remoteDataSource: VisitsRemoteDataSource(),
          ),
        ),
        Provider<SavedTripItineraryRepository>(
          create: (_) => SavedTripItineraryRepositoryImpl(
            remoteDataSource: SavedTripItineraryRemoteDataSource(),
          ),
        ),
        Provider<DayRouteRepository>(
          create: (_) => const DayRouteRepositoryImpl(
            remoteDataSource: DayRouteRemoteDataSource(),
          ),
        ),
        Provider<SavedTripRepository>(
          create: (_) => SavedTripRepositoryImpl(
            remoteDataSource: SavedTripRemoteDataSource(),
          ),
        ),
        Provider<ProgressRepository>(
          create: (_) => ProgressRepositoryImpl(
            remoteDataSource: ProgressRemoteDataSource(),
          ),
        ),
        Provider<OfflineCityPackRepository>(
          create: (context) => OfflineCityPackRepositoryImpl(
            exploreRepository: context.read<ExploreRepository>(),
            foodRepository: context.read<FoodRepository>(),
            cultureRepository: context.read<CultureRepository>(),
            localDataSource: context.read<OfflineCityPackLocalDataSource>(),
          ),
        ),
        Provider<LocationService>(
          create: (_) => const LocationService(),
        ),
        Provider<DetectArrival>(
          create: (context) => DetectArrival(
            distanceCalculator: context.read<LocationService>().distanceMeters,
          ),
        ),
        Provider<FindNearbyDiscoveries>(
          create: (context) => FindNearbyDiscoveries(
            distanceCalculator: context.read<LocationService>().distanceMeters,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            repository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SubscriptionProvider(
            repository: context.read<SubscriptionRepository>(),
            authProvider: context.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => PurchaseProvider(
            repository: context.read<PurchaseRepository>(),
            authProvider: context.read<AuthProvider>(),
            subscriptionProvider: context.read<SubscriptionProvider>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(
          create: (context) => LocationProvider(
            locationService: context.read<LocationService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ArrivalDetectionProvider(
            repository: context.read<ArrivalDetectionRepository>(),
            travelHistoryRepository: context.read<TravelHistoryRepository>(),
            authProvider: context.read<AuthProvider>(),
            detectArrival: context.read<DetectArrival>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => NearbyProvider(
            locationProvider: context.read<LocationProvider>(),
            findNearbyDiscoveries: context.read<FindNearbyDiscoveries>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => FavoritesProvider(
            repository: context.read<FavoriteRepository>(),
            exploreRepository: context.read<ExploreRepository>(),
            authProvider: context.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ProgressProvider(
            repository: context.read<ProgressRepository>(),
            authProvider: context.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SavedTripsProvider(
            repository: context.read<SavedTripRepository>(),
            authProvider: context.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SavedTripItineraryProvider(
            repository: context.read<SavedTripItineraryRepository>(),
            authProvider: context.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => DayRouteProvider(
            repository: context.read<DayRouteRepository>(),
            authProvider: context.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => TravelHistoryProvider(
            repository: context.read<TravelHistoryRepository>(),
            authProvider: context.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => VisitsProvider(
            repository: context.read<VisitsRepository>(),
            authProvider: context.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => TravelMemoryProvider(
            repository: context.read<TravelJournalRepository>(),
            authProvider: context.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => FoodFilterProvider(
            repository: context.read<FoodRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => CultureGuideProvider(
            repository: context.read<CultureRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => OfflineCityPackProvider(
            repository: context.read<OfflineCityPackRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TripPlannerProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => TravelAssistantProvider(
            repository: context.read<TravelAssistantRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ArrivalGuideProvider(
            repository: context.read<ArrivalGuideRepository>(),
          ),
        ),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final _router = AppRouter.create(
    context.read<AuthProvider>(),
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Edible',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: _router,
    );
  }
}