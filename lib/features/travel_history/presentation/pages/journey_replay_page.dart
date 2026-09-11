import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/entities/travel_visit.dart';
import '../providers/travel_history_provider.dart';

class JourneyReplayPage extends StatefulWidget {
  const JourneyReplayPage({super.key});

  @override
  State<JourneyReplayPage> createState() => _JourneyReplayPageState();
}

class _JourneyReplayPageState extends State<JourneyReplayPage> {
  GoogleMapController? _mapController;
  bool _mapReady = false;
  TravelVisit? _pendingFocusVisit;

  Timer? _playTimer;
  bool _didInitialLoad = false;
  bool _isPlaying = false;
  int _visibleCount = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInitialLoad) return;
    _didInitialLoad = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<TravelHistoryProvider>().refresh();
      if (!mounted) return;

      final visits = _validVisits(
        context.read<TravelHistoryProvider>().visits,
      );

      setState(() {
        _visibleCount = visits.isEmpty ? 0 : 1;
      });

      if (visits.isNotEmpty) {
        _focusVisit(visits.first);
      }
    });
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    super.dispose();
  }

  List<TravelVisit> _validVisits(List<TravelVisit> source) {
    final visits = source
        .where((visit) {
          final lat = visit.latitude;
          final lng = visit.longitude;
          return lat != null &&
              lng != null &&
              lat >= -90 &&
              lat <= 90 &&
              lng >= -180 &&
              lng <= 180;
        })
        .toList(growable: false);

    visits.sort((a, b) {
      final date = a.visitDay.compareTo(b.visitDay);
      if (date != 0) return date;
      return a.firstSeenAt.compareTo(b.firstSeenAt);
    });

    return visits;
  }

  Future<void> _focusVisit(TravelVisit visit) async {
    final lat = visit.latitude;
    final lng = visit.longitude;
    if (lat == null || lng == null) return;
    final controller = _mapController;
    if (!_mapReady || controller == null) {
      _pendingFocusVisit = visit;
      return;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 5.2),
    );
  }

  void _showStep(int value, List<TravelVisit> visits) {
    if (visits.isEmpty) return;

    final next = value.clamp(1, visits.length);

    setState(() {
      _visibleCount = next;
    });

    _focusVisit(visits[next - 1]);
  }

  void _togglePlayback(List<TravelVisit> visits) {
    if (visits.isEmpty) return;

    if (_isPlaying) {
      _stopPlayback();
      return;
    }

    if (_visibleCount >= visits.length) {
      _visibleCount = 1;
      _focusVisit(visits.first);
    }

    setState(() => _isPlaying = true);

    _playTimer?.cancel();
    _playTimer = Timer.periodic(
      const Duration(milliseconds: 1200),
      (_) {
        if (!mounted) {
          _playTimer?.cancel();
          return;
        }

        if (_visibleCount >= visits.length) {
          _stopPlayback();
          return;
        }

        _showStep(_visibleCount + 1, visits);
      },
    );
  }

  void _stopPlayback() {
    _playTimer?.cancel();
    _playTimer = null;

    if (mounted) {
      setState(() => _isPlaying = false);
    } else {
      _isPlaying = false;
    }
  }

  Future<void> _openMemory(TravelVisit visit) async {
    _stopPlayback();

    await context.push(
      AppRoutes.travelMemoryFor(visit.id),
    );

    if (!mounted) return;
    await context.read<TravelHistoryProvider>().refresh();
  }

  String _date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<TravelHistoryProvider>();
    final visits = _validVisits(history.visits);
    final visible = visits.take(_visibleCount).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('journeyReplay')),
      ),
      body: history.isLoading && history.visits.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : history.errorMessage != null && history.visits.isEmpty
              ? _ReplayState(
                  icon: Icons.cloud_off_rounded,
                  title: context.l10n.text('journeyReplayLoadFailed'),
                  message: context.l10n.text('journeyReplayLoadFailedMessage'),
                  action: FilledButton.tonalIcon(
                    onPressed: history.refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.l10n.text('retry')),
                  ),
                )
              : visits.isEmpty
                  ? _ReplayState(
                      icon: Icons.route_outlined,
                      title: context.l10n.text('journeyReplayEmptyTitle'),
                      message: context.l10n.text('journeyReplayEmptyMessage'),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: const CameraPosition(
                                  target: LatLng(20, 0),
                                  zoom: 2.1,
                                ),
                                minMaxZoomPreference: const MinMaxZoomPreference(1.5, 12),
                                zoomControlsEnabled: false,
                                markers: {
                                  for (var index = 0; index < visible.length; index++)
                                    Marker(
                                      markerId: MarkerId('replay-${visible[index].id}'),
                                      position: LatLng(
                                        visible[index].latitude!,
                                        visible[index].longitude!,
                                      ),
                                      icon: BitmapDescriptor.defaultMarkerWithHue(
                                        index == visible.length - 1
                                            ? BitmapDescriptor.hueAzure
                                            : BitmapDescriptor.hueOrange,
                                      ),
                                      consumeTapEvents: true,
                                      onTap: () => _openMemory(visible[index]),
                                    ),
                                },
                                polylines: visible.length > 1
                                    ? {
                                        Polyline(
                                          polylineId: const PolylineId('journey-replay'),
                                          points: visible
                                              .map(
                                                (visit) => LatLng(
                                                  visit.latitude!,
                                                  visit.longitude!,
                                                ),
                                              )
                                              .toList(growable: false),
                                          width: 5,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      }
                                    : const <Polyline>{},
                                onMapCreated: (controller) {
                                  if (!mounted) return;
                                  setState(() {
                                    _mapController = controller;
                                    _mapReady = true;
                                  });
                                  final pending = _pendingFocusVisit;
                                  _pendingFocusVisit = null;
                                  if (pending != null) {
                                    _focusVisit(pending);
                                  }
                                },
                              ),
                              Positioned(
                                left: 16,
                                right: 16,
                                top: 16,
                                child: _ReplaySummary(
                                  current: visible.last,
                                  currentIndex: visible.length,
                                  total: visits.length,
                                  date: _date(visible.last.visitDay),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SafeArea(
                          top: false,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              14,
                              16,
                              14,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border(
                                top: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    IconButton.filledTonal(
                                      tooltip: _isPlaying
                                          ? context.l10n.text('pauseReplay')
                                          : context.l10n.text('playReplay'),
                                      onPressed: () =>
                                          _togglePlayback(visits),
                                      icon: Icon(
                                        _isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Slider(
                                        min: 1,
                                        max: visits.length.toDouble(),
                                        divisions: visits.length > 1
                                            ? visits.length - 1
                                            : null,
                                        value: _visibleCount
                                            .clamp(1, visits.length)
                                            .toDouble(),
                                        onChanged: visits.length == 1
                                            ? null
                                            : (value) {
                                                _stopPlayback();
                                                _showStep(
                                                  value.round(),
                                                  visits,
                                                );
                                              },
                                      ),
                                    ),
                                    SizedBox(
                                      width: 54,
                                      child: Text(
                                        '$_visibleCount/${visits.length}',
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        context.l10n.text(
                                          'journeyReplayPathDisclaimer',
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _ReplayMarker extends StatelessWidget {
  const _ReplayMarker({
    required this.number,
    required this.isCurrent,
    required this.onTap,
  });

  final int number;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: isCurrent ? 44 : 36,
            height: isCurrent ? 44 : 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCurrent ? scheme.primary : scheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrent ? scheme.onPrimary : scheme.primary,
                width: 2,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.32),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : const [],
            ),
            child: Text(
              '$number',
              style: TextStyle(
                color: isCurrent ? scheme.onPrimary : scheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Icon(
            Icons.arrow_drop_down_rounded,
            color: scheme.primary,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _ReplaySummary extends StatelessWidget {
  const _ReplaySummary({
    required this.current,
    required this.currentIndex,
    required this.total,
    required this.date,
  });

  final TravelVisit current;
  final int currentIndex;
  final int total;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(22),
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$currentIndex',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    current.locationLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$date • $currentIndex/$total',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: context.l10n.text('openTripMemory'),
              onPressed: () => context.push(
                AppRoutes.travelMemoryFor(current.id),
              ),
              icon: const Icon(Icons.photo_album_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplayState extends StatelessWidget {
  const _ReplayState({
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
        padding: const EdgeInsets.all(30),
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

