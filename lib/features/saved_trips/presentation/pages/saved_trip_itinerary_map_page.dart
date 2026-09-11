import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/config/routing_config.dart';
import '../../../explore/domain/repositories/explore_repository.dart';
import '../../domain/entities/day_route.dart';
import '../../domain/entities/saved_trip_itinerary.dart';
import '../../domain/services/day_route_coordinate_policy.dart';
import '../providers/day_route_provider.dart';
import '../providers/saved_trip_itinerary_provider.dart';
import '../providers/saved_trips_provider.dart';

class SavedTripItineraryMapPage extends StatefulWidget {
  const SavedTripItineraryMapPage({
    required this.tripId,
    required this.dayIndex,
    super.key,
  });

  final String tripId;
  final int dayIndex;

  @override
  State<SavedTripItineraryMapPage> createState() =>
      _SavedTripItineraryMapPageState();
}

class _SavedTripItineraryMapPageState
    extends State<SavedTripItineraryMapPage> {
  bool _requested = false;
  bool _bootstrapping = true;
  String? _bootstrapError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    setState(() {
      _bootstrapping = true;
      _bootstrapError = null;
    });

    try {
      final trips = context.read<SavedTripsProvider>();
      if (trips.byId(widget.tripId) == null) {
        await trips.refresh();
      }

      if (!mounted) return;

      final trip = trips.byId(widget.tripId);
      if (trip == null) {
        setState(() => _bootstrapping = false);
        return;
      }

      final languageCode =
          Localizations.localeOf(context).languageCode;
      final allContents =
          await context.read<ExploreRepository>().getContents(
                languageCode: languageCode,
              );

      if (!mounted) return;

      final targetCity = trip.cityName.trim().toLowerCase();
      final destinationContents = allContents
          .where((item) {
            final sameCountry =
                item.countryCode.toLowerCase() ==
                    trip.countryCode.toLowerCase();
            if (!sameCountry) return false;

            // A country-wide vacation intentionally stores an empty city.
            // Loading the map must therefore use every city in that country,
            // not filter for the impossible value `cityName == ''`.
            if (targetCity.isEmpty) return true;

            return item.cityName.trim().toLowerCase() == targetCity;
          })
          .toList(growable: false);

      await context.read<SavedTripItineraryProvider>().load(
            tripId: trip.id,
            cityContents: destinationContents,
          );

      if (!mounted) return;

      setState(() => _bootstrapping = false);
      await _loadRoute();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _bootstrapError = error.toString();
        _bootstrapping = false;
      });
    }
  }

  Future<void> _loadRoute({bool force = false}) {
    final stops = context
        .read<SavedTripItineraryProvider>()
        .forDay(widget.dayIndex);

    return context.read<DayRouteProvider>().load(
          tripId: widget.tripId,
          dayIndex: widget.dayIndex,
          stops: stops,
          force: force,
        );
  }

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<SavedTripsProvider>();
    final itinerary = context.watch<SavedTripItineraryProvider>();
    final routeState = context.watch<DayRouteProvider>();
    final trip = trips.byId(widget.tripId);

    if (_bootstrapping) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_bootstrapError != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _bootstrapError!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _bootstrap,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.text('retry')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(context.l10n.text('savedTripNotFound')),
        ),
      );
    }

    if (widget.dayIndex < 0 || widget.dayIndex >= trip.dayCount) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              context.l10n.text('itineraryDayUnavailable'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final stops = itinerary.forDay(widget.dayIndex);
    final route = routeState.routeFor(widget.tripId, widget.dayIndex);
    final loading = routeState.isLoading(widget.tripId, widget.dayIndex);
    final routeError = routeState.errorFor(widget.tripId, widget.dayIndex);
    final coordinateSafe =
        DayRouteCoordinatePolicy.hasVerifiedExactCoordinates(stops);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${context.l10n.text('day')} ${widget.dayIndex + 1} • '
          '${context.l10n.text('routeMap')}',
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.text('refreshRoute'),
            onPressed: loading ? null : () => _loadRoute(force: true),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: context.l10n.text('optimizeRoute'),
            onPressed: !itinerary.canOptimizeDay(widget.dayIndex) ||
                    itinerary.isSaving
                ? null
                : () async {
                    final result =
                        await itinerary.optimizeDay(widget.dayIndex);
                    if (!mounted) return;

                    if (result == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            itinerary.errorMessage ??
                                context.l10n.text(
                                  'somethingWentWrong',
                                ),
                          ),
                        ),
                      );
                      return;
                    }

                    context.read<DayRouteProvider>().invalidate(
                          widget.tripId,
                          widget.dayIndex,
                        );
                    await _loadRoute(force: true);
                  },
            icon: const Icon(Icons.auto_fix_high),
          ),
        ],
      ),
      body: stops.isEmpty
          ? Center(child: Text(context.l10n.text('freeDay')))
          : Stack(
              children: [
                _DayRouteMap(
                  stops: stops,
                  route: route,
                  coordinateSafe: coordinateSafe,
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: _RouteInfoCard(
                    route: route,
                    loading: loading,
                    routeError: routeError,
                    coordinateSafe: coordinateSafe,
                  ),
                ),
              ],
            ),
    );
  }
}

class _DayRouteMap extends StatelessWidget {
  const _DayRouteMap({
    required this.stops,
    required this.route,
    required this.coordinateSafe,
  });

  final List<SavedTripItineraryStop> stops;
  final DayRoute? route;
  final bool coordinateSafe;

  @override
  Widget build(BuildContext context) {
    final stopPoints = stops
        .map(
          (stop) => LatLng(
            stop.content.latitude,
            stop.content.longitude,
          ),
        )
        .toList(growable: false);

    final hasRoadRoute = coordinateSafe &&
        route?.isRoadRoute == true &&
        (route?.coordinates.length ?? 0) >= 2;

    final routePoints = hasRoadRoute
        ? route!.coordinates
            .map(
              (point) => LatLng(
                point.latitude,
                point.longitude,
              ),
            )
            .toList(growable: false)
        : const <LatLng>[];

    final framingPoints =
        routePoints.isEmpty ? stopPoints : routePoints;

    final latitudes =
        framingPoints.map((point) => point.latitude).toList();
    final longitudes =
        framingPoints.map((point) => point.longitude).toList();

    final minLatitude = latitudes.reduce((a, b) => a < b ? a : b);
    final maxLatitude = latitudes.reduce((a, b) => a > b ? a : b);
    final minLongitude = longitudes.reduce((a, b) => a < b ? a : b);
    final maxLongitude = longitudes.reduce((a, b) => a > b ? a : b);

    final center = LatLng(
      (minLatitude + maxLatitude) / 2,
      (minLongitude + maxLongitude) / 2,
    );

    final latSpan = (maxLatitude - minLatitude).abs();
    final lngSpan = (maxLongitude - minLongitude).abs();
    final span = latSpan > lngSpan ? latSpan : lngSpan;

    final initialZoom = stops.length == 1
        ? 15.0
        : span < 0.01
            ? 14.0
            : span < 0.03
                ? 13.0
                : span < 0.08
                    ? 12.0
                    : span < 0.18
                        ? 11.0
                        : 10.0;

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: center,
        zoom: initialZoom,
      ),
      minMaxZoomPreference: const MinMaxZoomPreference(3, 18),
      zoomControlsEnabled: false,
      polylines: hasRoadRoute
          ? {
              Polyline(
                polylineId: const PolylineId('saved-trip-route'),
                points: routePoints,
                width: 5,
                color: Theme.of(context).colorScheme.primary,
              ),
            }
          : const <Polyline>{},
      markers: {
        for (var index = 0; index < stops.length; index++)
          Marker(
            markerId: MarkerId('saved-trip-stop-$index'),
            position: stopPoints[index],
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: InfoWindow(
              title: '${index + 1}. ${stops[index].timeLabel}',
            ),
          ),
      },
    );
  }
}

class _RouteInfoCard extends StatelessWidget {
  const _RouteInfoCard({
    required this.route,
    required this.loading,
    required this.routeError,
    required this.coordinateSafe,
  });

  final DayRoute? route;
  final bool loading;
  final String? routeError;
  final bool coordinateSafe;

  String _distance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _duration(double minutes) {
    if (minutes < 60) return '${minutes.round()} min';
    final hours = minutes ~/ 60;
    final remainder = (minutes % 60).round();
    return '${hours}h ${remainder}m';
  }

  @override
  Widget build(BuildContext context) {
    final current = route;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        child: !coordinateSafe
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_searching_rounded),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.text('routeExactCoordinatesRequired'),
                    ),
                  ),
                ],
              )
            : loading
                ? Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(context.l10n.text('loadingRoute')),
                      ),
                    ],
                  )
                : routeError != null || current == null || !current.isRoadRoute
                    ? Text(context.l10n.text('routeUnavailable'))
                    : Row(
                        children: [
                          const Icon(Icons.directions_walk),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_distance(current.distanceMeters)} • '
                              '${_duration(current.durationMinutes)} • '
                              '${context.l10n.text('walkingRoute')}',
                            ),
                          ),
                          Tooltip(
                            message: RoutingConfig.hasApiKey
                                ? context.l10n.text('configuredRoutingProvider')
                                : context.l10n.text('developmentRoutingProvider'),
                            child: const Icon(
                              Icons.info_outline,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}

class _RouteMarker extends StatelessWidget {
  const _RouteMarker({
    required this.number,
    required this.time,
  });

  final int number;
  final String time;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: scheme.onPrimary,
              width: 2,
            ),
          ),
          child: Text(
            '$number',
            style: TextStyle(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 1,
            ),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

