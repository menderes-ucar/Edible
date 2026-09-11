import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/entities/country_visit_badge.dart';
import '../providers/visits_provider.dart';

class VisitedWorldMapPage extends StatefulWidget {
  const VisitedWorldMapPage({super.key});

  @override
  State<VisitedWorldMapPage> createState() => _VisitedWorldMapPageState();
}

class _VisitedWorldMapPageState extends State<VisitedWorldMapPage> {
  GoogleMapController? _mapController;
  bool _mapReady = false;
  bool _didRefresh = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didRefresh) return;
    _didRefresh = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<VisitsProvider>().refresh();
      if (!mounted) return;
      _fitVisitedCountries();
    });
  }

  void _fitVisitedCountries() {
    final badges = context.read<VisitsProvider>().mappableBadges;
    if (badges.isEmpty) return;

    final points = badges
        .map((badge) => LatLng(badge.latestLatitude!, badge.latestLongitude!))
        .toList(growable: false);

    final latitudes = points.map((point) => point.latitude).toList();
    final longitudes = points.map((point) => point.longitude).toList();

    final minLat = latitudes.reduce((a, b) => a < b ? a : b);
    final maxLat = latitudes.reduce((a, b) => a > b ? a : b);
    final minLng = longitudes.reduce((a, b) => a < b ? a : b);
    final maxLng = longitudes.reduce((a, b) => a > b ? a : b);

    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    final latSpan = (maxLat - minLat).abs();
    final lngSpan = (maxLng - minLng).abs();
    final span = latSpan > lngSpan ? latSpan : lngSpan;

    final zoom = badges.length == 1
        ? 5.2
        : span < 5
            ? 5.0
            : span < 15
                ? 4.0
                : span < 45
                    ? 3.0
                    : 2.1;

    final controller = _mapController;
    if (!_mapReady || controller == null) return;
    controller.animateCamera(CameraUpdate.newLatLngZoom(center, zoom));
  }

  Future<void> _openBadge(CountryVisitBadge badge) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _CountryMapSheet(
        badge: badge,
        onOpenMemory: () {
          Navigator.pop(sheetContext);
          context.push(AppRoutes.travelMemoryFor(badge.latestVisitId));
        },
      ),
    );

    if (!mounted) return;
    await context.read<VisitsProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final visits = context.watch<VisitsProvider>();
    final badges = visits.mappableBadges;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('visitedWorldMap')),
        actions: [
          IconButton(
            tooltip: context.l10n.text('fitVisitedCountries'),
            onPressed: badges.isEmpty ? null : _fitVisitedCountries,
            icon: const Icon(Icons.center_focus_strong_rounded),
          ),
        ],
      ),
      body: visits.isLoading && visits.badges.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : visits.hasError && visits.badges.isEmpty
              ? _MapState(
                  icon: Icons.cloud_off_rounded,
                  title: context.l10n.text('visitsLoadFailed'),
                  message: context.l10n.text('visitsLoadFailedMessage'),
                  action: FilledButton.tonalIcon(
                    onPressed: visits.refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.l10n.text('retry')),
                  ),
                )
              : badges.isEmpty
                  ? _MapState(
                      icon: Icons.public_off_outlined,
                      title: context.l10n.text('worldMapEmptyTitle'),
                      message: context.l10n.text('worldMapEmptyMessage'),
                    )
                  : Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: const CameraPosition(
                            target: LatLng(20, 0),
                            zoom: 2.1,
                          ),
                          minMaxZoomPreference: const MinMaxZoomPreference(1.5, 12),
                          zoomControlsEnabled: false,
                          markers: badges
                              .map(
                                (badge) => Marker(
                                  markerId: MarkerId(badge.latestVisitId),
                                  position: LatLng(
                                    badge.latestLatitude!,
                                    badge.latestLongitude!,
                                  ),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueAzure,
                                  ),
                                  consumeTapEvents: true,
                                  onTap: () => _openBadge(badge),
                                ),
                              )
                              .toSet(),
                          onMapCreated: (controller) {
                            if (!mounted) return;
                            setState(() {
                              _mapController = controller;
                              _mapReady = true;
                            });
                            _fitVisitedCountries();
                          },
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          top: 16,
                          child: _MapSummary(
                            totalCountries: visits.countryCount,
                            mappedCountries: badges.length,
                            shiningCountries: visits.unlockedCount,
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _WorldMarker extends StatelessWidget {
  const _WorldMarker({
    required this.badge,
    required this.onTap,
  });

  final CountryVisitBadge badge;
  final VoidCallback onTap;

  String _flag(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.length != 2) return '🌍';

    return String.fromCharCodes(
      normalized.codeUnits.map((unit) => unit + 127397),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cover = badge.coverPhotoUrl;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surface,
              border: Border.all(
                color: badge.isUnlocked ? scheme.primary : scheme.outline,
                width: badge.isUnlocked ? 3 : 2,
              ),
              boxShadow: badge.isUnlocked
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.34),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : const [],
              image: cover == null || cover.trim().isEmpty
                  ? null
                  : DecorationImage(
                      image: NetworkImage(cover),
                      fit: BoxFit.cover,
                    ),
            ),
            alignment: Alignment.center,
            child: cover == null || cover.trim().isEmpty
                ? Text(
                    _flag(badge.countryCode),
                    style: const TextStyle(fontSize: 30),
                  )
                : null,
          ),
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge.normalizedCountryCode,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapSummary extends StatelessWidget {
  const _MapSummary({
    required this.totalCountries,
    required this.mappedCountries,
    required this.shiningCountries,
  });

  final int totalCountries;
  final int mappedCountries;
  final int shiningCountries;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.public_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$mappedCountries/$totalCountries '
                '${context.l10n.text('countriesMapped')}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const Icon(Icons.auto_awesome_rounded, size: 18),
            const SizedBox(width: 4),
            Text('$shiningCountries'),
          ],
        ),
      ),
    );
  }
}

class _CountryMapSheet extends StatelessWidget {
  const _CountryMapSheet({
    required this.badge,
    required this.onOpenMemory,
  });

  final CountryVisitBadge badge;
  final VoidCallback onOpenMemory;

  @override
  Widget build(BuildContext context) {
    final cover = badge.coverPhotoUrl;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cover != null && cover.trim().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    cover,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Colors.black12),
                  ),
                ),
              ),
            if (cover != null && cover.trim().isNotEmpty)
              const SizedBox(height: 16),
            Text(
              badge.countryName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${badge.cityCount} ${context.l10n.text('cities')} • '
              '${badge.visitCount} ${context.l10n.text('travelDays')} • '
              '${badge.photoCount} ${context.l10n.text('travelPhotos')}',
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpenMemory,
                icon: const Icon(Icons.photo_album_outlined),
                label: Text(context.l10n.text('openTripMemory')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevelopmentTileNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.text('productionMapTileNotice'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapState extends StatelessWidget {
  const _MapState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 62),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

