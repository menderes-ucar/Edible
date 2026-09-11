import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_error_presenter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../explore/domain/entities/explore_content.dart';
import '../../../explore/domain/repositories/explore_repository.dart';
import '../../domain/entities/saved_trip_itinerary.dart';
import '../../domain/entities/itinerary_route_optimization.dart';
import '../../domain/services/itinerary_regeneration_policy.dart';
import '../../domain/services/itinerary_day_summary.dart';
import '../../domain/services/itinerary_day_city_summary.dart';
import '../../domain/services/itinerary_unscheduled_discoveries.dart';
import '../../domain/services/free_day_discovery_policy.dart';
import '../../domain/services/itinerary_day_planning_policy.dart';
import '../../domain/usecases/generate_saved_trip_itinerary.dart';
import '../providers/saved_trip_itinerary_provider.dart';
import '../providers/saved_trips_provider.dart';

class SavedTripItineraryPage extends StatefulWidget {
  const SavedTripItineraryPage({
    required this.tripId,
    super.key,
  });

  final String tripId;

  @override
  State<SavedTripItineraryPage> createState() =>
      _SavedTripItineraryPageState();
}

class _SavedTripItineraryPageState
    extends State<SavedTripItineraryPage> {
  List<ExploreContent>? _cityContents;
  String? _loadedLanguage;
  String? _loadError;
  int _loadRequestId = 0;
  final List<GlobalKey> _dayKeys =
      List<GlobalKey>.generate(30, (_) => GlobalKey());

  Future<void> _jumpToDay(int dayIndex) async {
    if (dayIndex < 0 || dayIndex >= _dayKeys.length) return;
    final targetContext = _dayKeys[dayIndex].currentContext;
    if (targetContext == null) return;
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.06,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final language = Localizations.localeOf(context).languageCode;
    if (_loadedLanguage == language) return;

    _loadedLanguage = language;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _load(language),
    );
  }

  @override
  void didUpdateWidget(covariant SavedTripItineraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tripId == widget.tripId) return;

    _loadRequestId++;
    _cityContents = null;
    _loadError = null;

    final language =
        _loadedLanguage ?? Localizations.localeOf(context).languageCode;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _load(language),
    );
  }

  Future<void> _load(String languageCode) async {
    final requestId = ++_loadRequestId;
    final tripId = widget.tripId;

    if (mounted) {
      setState(() {
        _cityContents = null;
        _loadError = null;
      });
    }

    try {
      final trips = context.read<SavedTripsProvider>();

      if (trips.byId(tripId) == null) {
        await trips.refresh();
      }

      if (!mounted ||
          requestId != _loadRequestId ||
          widget.tripId != tripId ||
          _loadedLanguage != languageCode) {
        return;
      }

      final trip = trips.byId(tripId);
      if (trip == null) {
        setState(() => _cityContents = const []);
        return;
      }

      final all = await context.read<ExploreRepository>().getContents(
            languageCode: languageCode,
          );

      if (!mounted ||
          requestId != _loadRequestId ||
          widget.tripId != tripId ||
          _loadedLanguage != languageCode) {
        return;
      }

      final country = trip.countryCode.toLowerCase();
      final city = trip.cityName.trim().toLowerCase();
      final cityContents = all
          .where(
            (item) =>
                item.countryCode.toLowerCase() == country &&
                (city.isEmpty || item.cityName.toLowerCase() == city),
          )
          .toList(growable: false);

      setState(() {
        _cityContents = cityContents;
        _loadError = null;
      });

      await context.read<SavedTripItineraryProvider>().load(
            tripId: trip.id,
            cityContents: cityContents,
          );
    } catch (error) {
      if (!mounted ||
          requestId != _loadRequestId ||
          widget.tripId != tripId ||
          _loadedLanguage != languageCode) {
        return;
      }

      setState(() {
        _loadError = AppErrorPresenter.message(context, error);
      });
    }
  }

  @override
  void dispose() {
    _loadRequestId++;
    super.dispose();
  }

  DateTime _dayDate(DateTime start, int dayIndex) {
    return start.add(Duration(days: dayIndex));
  }

  String _date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<void> _reloadItinerary() async {
    final trip = context.read<SavedTripsProvider>().byId(widget.tripId);
    final contents = _cityContents ?? const <ExploreContent>[];
    if (trip == null) return;

    await context.read<SavedTripItineraryProvider>().load(
          tripId: trip.id,
          cityContents: contents,
        );
  }

  Future<void> _generate() async {
    final trip = context.read<SavedTripsProvider>().byId(widget.tripId);
    final cityContents = _cityContents;

    if (trip == null || cityContents == null) return;

    final selected = cityContents
        .where((content) => trip.contentIds.contains(content.id))
        .toList(growable: false);

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.text('itineraryNeedsDiscoveries'),
          ),
        ),
      );
      return;
    }

    final itinerary = context.read<SavedTripItineraryProvider>();
    if (ItineraryRegenerationPolicy.requiresConfirmation(
      persistedStopCount: itinerary.stops.length,
      unresolvedStopCount: itinerary.unresolvedStopCount,
    )) {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(
                context.l10n.text('regenerateItineraryConfirmTitle'),
              ),
              content: Text(
                context.l10n.text('regenerateItineraryConfirmMessage'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(context.l10n.text('cancel')),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(context.l10n.text('regenerateItinerary')),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed || !mounted) return;
    }

    final success =
        await itinerary.generateAndSave(
              trip: trip,
              selectedContents: selected,
            );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? context.l10n.text('itineraryGenerated')
              : itinerary.errorCode == 'itinerary_capacity_exceeded'
                  ? context.l10n
                      .text('itineraryCapacityExceeded')
                      .replaceAll(
                        '{count}',
                        '${itinerary.itineraryCapacityLimit ?? selected.length}',
                      )
                  : context.l10n.text(
                      itinerary.errorCode ==
                              'content_not_synced_to_supabase'
                          ? 'itineraryCatalogSyncRequired'
                          : 'itineraryGenerateFailed',
                    ),
        ),
      ),
    );
  }

  Future<void> _addUnscheduledContent(
    ExploreContent content,
  ) async {
    final trip = context.read<SavedTripsProvider>().byId(widget.tripId);
    final itinerary = context.read<SavedTripItineraryProvider>();
    if (trip == null) return;

    final selectedDay = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _AddToDaySheet(
        dayCount: trip.dayCount,
        stops: itinerary.stops,
      ),
    );

    if (selectedDay == null || !mounted) return;

    final success = await itinerary.addContentToDay(
      trip: trip,
      content: content,
      dayIndex: selectedDay,
    );

    if (!mounted) return;

    if (!success) {
      final code = itinerary.errorCode;
      final message = code == 'itinerary_day_capacity_exceeded'
          ? context.l10n.text('itineraryCapacityExceeded').replaceAll(
                '{count}',
                '${GenerateSavedTripItinerary.maxStopsPerDay}',
              )
          : code == 'itinerary_content_already_scheduled'
              ? context.l10n.text('itineraryAlreadyScheduled')
              : context.l10n.text('itineraryAddFailed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.text('itineraryAddedToDay'))),
    );
  }

  Future<void> _pickDiscoveryForDay(
    int dayIndex,
    List<ExploreContent> unscheduled,
  ) async {
    final trip = context.read<SavedTripsProvider>().byId(widget.tripId);
    final itinerary = context.read<SavedTripItineraryProvider>();
    if (trip == null || unscheduled.isEmpty) return;
    if (dayIndex < 0 || dayIndex >= trip.dayCount) return;

    final selected = await showModalBottomSheet<ExploreContent>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _DiscoveryForDaySheet(
        dayNumber: dayIndex + 1,
        contents: unscheduled,
      ),
    );

    if (selected == null || !mounted) return;

    final success = await itinerary.addContentToDay(
      trip: trip,
      content: selected,
      dayIndex: dayIndex,
    );

    if (!mounted) return;

    if (!success) {
      final code = itinerary.errorCode;
      final message = code == 'itinerary_day_capacity_exceeded'
          ? context.l10n.text('itineraryCapacityExceeded').replaceAll(
                '{count}',
                '${GenerateSavedTripItinerary.maxStopsPerDay}',
              )
          : code == 'itinerary_content_already_scheduled'
              ? context.l10n.text('itineraryAlreadyScheduled')
              : context.l10n.text('itineraryAddFailed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.text('itineraryAddedToDay'))),
    );
  }

  Future<void> _runMutation(
    Future<bool> Function() operation,
  ) async {
    final ok = await operation();
    if (!mounted || ok) return;
    _showMutationFailure();
  }

  void _showMutationFailure() {
    if (!mounted) return;

    final itinerary = context.read<SavedTripItineraryProvider>();
    final message = itinerary.errorCode == 'content_not_synced_to_supabase'
        ? context.l10n.text('itineraryCatalogSyncRequired')
        : AppErrorPresenter.message(context, itinerary.errorMessage);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<SavedTripsProvider>();
    final itinerary = context.watch<SavedTripItineraryProvider>();
    final trip = trips.byId(widget.tripId);

    if (trip == null &&
        (trips.isLoading || _cityContents == null && _loadError == null)) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (trip == null && (trips.errorMessage != null || _loadError != null)) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadError ??
                      AppErrorPresenter.message(
                        context,
                        trips.errorMessage,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () => _load(
                    _loadedLanguage ??
                        Localizations.localeOf(context).languageCode,
                  ),
                  icon: const Icon(Icons.refresh_rounded),
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

    final unscheduled = _cityContents == null
        ? const <ExploreContent>[]
        : ItineraryUnscheduledDiscoveries.build(
            destinationContents: _cityContents!,
            savedContentIds: trip.contentIds,
            itineraryStops: itinerary.stops,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('dayByDayItinerary')),
      ),
      body: _cityContents == null && _loadError == null
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: () => _load(
                            _loadedLanguage ??
                                Localizations.localeOf(context).languageCode,
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(context.l10n.text('retry')),
                        ),
                      ],
                    ),
                  ),
                )
              : itinerary.isLoading && itinerary.stops.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
              onRefresh: _reloadItinerary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.route_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  trip.cityName.trim().isEmpty
                                      ? trip.countryName
                                      : '${trip.cityName}, ${trip.countryName}',
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_date(trip.startDate)} → ${_date(trip.endDate)} • '
                                  '${trip.dayCount} ${context.l10n.text('days')} • '
                                  '${trip.contentIds.length} ${context.l10n.text('savedPlaces')}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed:
                                itinerary.isSaving || itinerary.isLoading
                                    ? null
                                    : _generate,
                            icon: itinerary.isSaving || itinerary.isLoading
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: Text(
                              context.l10n.text(
                                itinerary.stops.isEmpty
                                    ? 'generateItinerary'
                                    : 'regenerateItinerary',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (itinerary.hasUnresolvedStops) ...[
                    const SizedBox(height: 12),
                    _UnresolvedItineraryStopsCard(
                      count: itinerary.unresolvedStopCount,
                      onRetry: _reloadItinerary,
                    ),
                  ],
                  if (itinerary.stops.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ItineraryDayNavigator(
                      summaries: ItineraryDaySummaryBuilder.build(
                        dayCount: trip.dayCount,
                        stops: itinerary.stops,
                      ),
                      onSelectDay: _jumpToDay,
                    ),
                  ],
                  if (unscheduled.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _UnscheduledDiscoveriesCard(
                      contents: unscheduled,
                      onRegenerate: itinerary.isSaving ? null : _generate,
                      onAddToDay: itinerary.isSaving
                          ? null
                          : _addUnscheduledContent,
                    ),
                  ],
                  if (itinerary.stops.isEmpty) ...[
                    const SizedBox(height: 24),
                    _ItineraryEmptyState(
                      hasSavedDiscoveries: trip.contentIds.isNotEmpty,
                      isBusy: itinerary.isSaving || itinerary.isLoading,
                      onGenerate: _generate,
                      onPickDiscoveries: () => context.go(
                        AppRoutes.savedTripDetailFor(trip.id),
                      ),
                    ),
                  ] else
                    ...List.generate(
                      trip.dayCount,
                      (dayIndex) {
                        final stops = itinerary.forDay(dayIndex);
                        final date = _dayDate(trip.startDate, dayIndex);

                        return Padding(
                          key: _dayKeys[dayIndex],
                          padding: const EdgeInsets.only(top: 18),
                          child: _DaySection(
                            dayNumber: dayIndex + 1,
                            dateLabel: _date(date),
                            stops: stops,
                            tripDayCount: trip.dayCount,
                            showCityContext: trip.cityName.trim().isEmpty,
                            isSaving: itinerary.isSaving,
                            canAddDiscovery:
                                FreeDayDiscoveryPolicy.canAdd(
                              stopCount: stops.length,
                              unscheduledCount: unscheduled.length,
                              isSaving: itinerary.isSaving,
                            ),
                            canAddDiscoveryToPlannedDay:
                                ItineraryDayPlanningPolicy.canAdd(
                              stopCount: stops.length,
                              maxStopsPerDay:
                                  GenerateSavedTripItinerary.maxStopsPerDay,
                              unscheduledCount: unscheduled.length,
                              isSaving: itinerary.isSaving,
                            ),
                            onAddDiscovery: () =>
                                _pickDiscoveryForDay(dayIndex, unscheduled),
                            onPreviousDay: (stop) => _runMutation(
                              () => itinerary.moveStop(
                                stop: stop,
                                newDayIndex: stop.dayIndex - 1,
                                tripDayCount: trip.dayCount,
                              ),
                            ),
                            onNextDay: (stop) => _runMutation(
                              () => itinerary.moveStop(
                                stop: stop,
                                newDayIndex: stop.dayIndex + 1,
                                tripDayCount: trip.dayCount,
                              ),
                            ),
                            onEarlier: (stop) => _runMutation(
                              () => itinerary.changeTime(
                                stop: stop,
                                deltaMinutes: -30,
                              ),
                            ),
                            onLater: (stop) => _runMutation(
                              () => itinerary.changeTime(
                                stop: stop,
                                deltaMinutes: 30,
                              ),
                            ),
                            optimization:
                                itinerary.optimizationForDay(dayIndex),
                            canOptimize: itinerary.canOptimizeDay(dayIndex),
                            onOptimize: () async {
                              final result =
                                  await itinerary.optimizeDay(dayIndex);
                              if (!mounted || result != null) return;
                              _showMutationFailure();
                            },
                            onOpenMap: () => context.push(
                              AppRoutes.savedTripItineraryMapFor(
                                tripId: trip.id,
                                dayIndex: dayIndex,
                              ),
                            ),
                            onRemove: (stop) => _runMutation(
                              () => itinerary.remove(stop),
                            ),
                          ),
                        );
                      },
                    ),
                  if (itinerary.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _ItineraryErrorCard(
                      message:
                          itinerary.errorCode == 'content_not_synced_to_supabase'
                              ? context.l10n.text(
                                  'itineraryCatalogSyncRequired',
                                )
                              : AppErrorPresenter.message(
                                  context,
                                  itinerary.errorMessage,
                                ),
                      retryEnabled: !itinerary.isLoading && !itinerary.isSaving,
                      onRetry: _reloadItinerary,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _UnresolvedItineraryStopsCard extends StatelessWidget {
  const _UnresolvedItineraryStopsCard({
    required this.count,
    required this.onRetry,
  });

  final int count;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.text('itineraryUnavailableStopsTitle'),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n
                        .text('itineraryUnavailableStopsMessage')
                        .replaceAll('{count}', count.toString()),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(context.l10n.text('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItineraryEmptyState extends StatelessWidget {
  const _ItineraryEmptyState({
    required this.hasSavedDiscoveries,
    required this.isBusy,
    required this.onGenerate,
    required this.onPickDiscoveries,
  });

  final bool hasSavedDiscoveries;
  final bool isBusy;
  final Future<void> Function() onGenerate;
  final VoidCallback onPickDiscoveries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.calendar_view_week_rounded, size: 46),
          const SizedBox(height: 12),
          Text(
            context.l10n.text(
              hasSavedDiscoveries
                  ? 'itineraryReadyEmptyTitle'
                  : 'itineraryNeedsPicksTitle',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            context.l10n.text(
              hasSavedDiscoveries
                  ? 'itineraryReadyEmptySubtitle'
                  : 'itineraryNeedsPicksSubtitle',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: hasSavedDiscoveries
                ? FilledButton.icon(
                    onPressed: isBusy ? null : onGenerate,
                    icon: isBusy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_rounded),
                    label: Text(
                      context.l10n.text('generateItinerary'),
                    ),
                  )
                : FilledButton.tonalIcon(
                    onPressed: onPickDiscoveries,
                    icon: const Icon(Icons.travel_explore_rounded),
                    label: Text(
                      context.l10n.text('pickTripDiscoveries'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ItineraryErrorCard extends StatelessWidget {
  const _ItineraryErrorCard({
    required this.message,
    required this.retryEnabled,
    required this.onRetry,
  });

  final String message;
  final bool retryEnabled;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.sync_problem_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: retryEnabled ? onRetry : null,
              child: Text(context.l10n.text('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryForDaySheet extends StatelessWidget {
  const _DiscoveryForDaySheet({
    required this.dayNumber,
    required this.contents,
  });

  final int dayNumber;
  final List<ExploreContent> contents;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.72,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n
                    .text('pickDiscoveryForDayTitle')
                    .replaceAll('{day}', '$dayNumber'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(context.l10n.text('pickDiscoveryForDaySubtitle')),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: contents.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final content = contents[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: const Icon(
                          Icons.place_outlined,
                          size: 19,
                        ),
                      ),
                      title: Text(
                        content.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        content.cityName.trim().isEmpty
                            ? content.countryName
                            : '${content.cityName}, ${content.countryName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.add_circle_outline_rounded),
                      onTap: () => Navigator.of(context).pop(content),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddToDaySheet extends StatelessWidget {
  const _AddToDaySheet({
    required this.dayCount,
    required this.stops,
  });

  final int dayCount;
  final List<SavedTripItineraryStop> stops;

  @override
  Widget build(BuildContext context) {
    final counts = List<int>.filled(dayCount, 0);
    for (final stop in stops) {
      if (stop.dayIndex >= 0 && stop.dayIndex < dayCount) {
        counts[stop.dayIndex]++;
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.text('itineraryChooseDayTitle'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(context.l10n.text('itineraryChooseDaySubtitle')),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: dayCount,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final count = counts[index];
                  final full =
                      count >= GenerateSavedTripItinerary.maxStopsPerDay;
                  return ListTile(
                    enabled: !full,
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text(
                      context.l10n
                          .text('itineraryChooseDayRow')
                          .replaceAll('{day}', '${index + 1}'),
                    ),
                    subtitle: Text(
                      context.l10n
                          .text('itineraryChooseDayStops')
                          .replaceAll('{count}', '$count')
                          .replaceAll(
                            '{max}',
                            '${GenerateSavedTripItinerary.maxStopsPerDay}',
                          ),
                    ),
                    trailing: full
                        ? Text(context.l10n.text('itineraryDayFull'))
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: full ? null : () => Navigator.of(context).pop(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnscheduledDiscoveriesCard extends StatelessWidget {
  const _UnscheduledDiscoveriesCard({
    required this.contents,
    required this.onRegenerate,
    required this.onAddToDay,
  });

  final List<ExploreContent> contents;
  final VoidCallback? onRegenerate;
  final ValueChanged<ExploreContent>? onAddToDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = contents.take(6).toList(growable: false);
    final remaining = contents.length - visible.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.playlist_add_check_circle_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.text('itineraryUnscheduledTitle'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  contents.length.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(context.l10n.text('itineraryUnscheduledSubtitle')),
            const SizedBox(height: 4),
            Text(
              context.l10n.text('itineraryUnscheduledHint'),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final content in visible)
                  ActionChip(
                    avatar: const Icon(Icons.add_location_alt_outlined,
                        size: 16),
                    label: Text(
                      content.cityName.trim().isEmpty
                          ? content.title
                          : '${content.title} · ${content.cityName}',
                    ),
                    onPressed: () {
                      if (onAddToDay != null) {
                        onAddToDay!(content);
                      } else {
                        context.push(
                          AppRoutes.contentDetail(content.id),
                          extra: content,
                        );
                      }
                    },
                  ),
                if (remaining > 0)
                  Chip(
                    label: Text(
                      context.l10n
                          .text('itineraryUnscheduledMore')
                          .replaceAll('{count}', remaining.toString()),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push(
                  AppRoutes.contentDetail(visible.first.id),
                  extra: visible.first,
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(context.l10n.text('itineraryOpenFirstDetail')),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: onRegenerate,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: Text(
                  context.l10n.text('itineraryUnscheduledRegenerate'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItineraryDayNavigator extends StatelessWidget {
  const _ItineraryDayNavigator({
    required this.summaries,
    required this.onSelectDay,
  });

  final List<ItineraryDaySummary> summaries;
  final ValueChanged<int> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plannedDays =
        summaries.where((summary) => !summary.isFreeDay).length;
    final totalStops =
        summaries.fold<int>(0, (sum, summary) => sum + summary.stopCount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_view_week_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.text('itineraryDayNavigatorTitle'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  context.l10n
                      .text('itineraryDayNavigatorSummary')
                      .replaceAll('{planned}', plannedDays.toString())
                      .replaceAll('{days}', summaries.length.toString())
                      .replaceAll('{stops}', totalStops.toString()),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var index = 0; index < summaries.length; index++) ...[
                    ActionChip(
                      avatar: Icon(
                        summaries[index].isFreeDay
                            ? Icons.event_available_outlined
                            : Icons.place_outlined,
                        size: 16,
                      ),
                      label: Text(
                        context.l10n
                            .text('itineraryDayNavigatorChip')
                            .replaceAll(
                              '{day}',
                              (summaries[index].dayIndex + 1).toString(),
                            )
                            .replaceAll(
                              '{count}',
                              summaries[index].stopCount.toString(),
                            ),
                      ),
                      onPressed: () =>
                          onSelectDay(summaries[index].dayIndex),
                    ),
                    if (index != summaries.length - 1)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.text('itineraryDayNavigatorHint'),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DayPlanningCapacityBar extends StatelessWidget {
  const _DayPlanningCapacityBar({
    required this.stopCount,
    required this.maxStopsPerDay,
    required this.canAddDiscovery,
    required this.onAddDiscovery,
  });

  final int stopCount;
  final int maxStopsPerDay;
  final bool canAddDiscovery;
  final VoidCallback onAddDiscovery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final full = ItineraryDayPlanningPolicy.isFull(
      stopCount: stopCount,
      maxStopsPerDay: maxStopsPerDay,
    );
    final ratio = ItineraryDayPlanningPolicy.fillRatio(
      stopCount: stopCount,
      maxStopsPerDay: maxStopsPerDay,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        full
                            ? context.l10n.text('itineraryDayCapacityFull')
                            : context.l10n.text('itineraryDayCapacityAvailable'),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '$stopCount/$maxStopsPerDay',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          if (canAddDiscovery) ...[
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: context.l10n.text('addDiscovery'),
              onPressed: onAddDiscovery,
              icon: const Icon(Icons.add_location_alt_outlined),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayCityContext extends StatelessWidget {
  const _DayCityContext({required this.cities});

  final List<ItineraryDayCitySummary> cities;

  @override
  Widget build(BuildContext context) {
    if (cities.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final city in cities)
          Chip(
            avatar: const Icon(Icons.location_city_outlined, size: 16),
            label: Text(
              context.l10n
                  .text('itineraryDayCityChip')
                  .replaceAll('{city}', city.cityName)
                  .replaceAll('{count}', city.stopCount.toString()),
            ),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.dayNumber,
    required this.dateLabel,
    required this.stops,
    required this.tripDayCount,
    required this.showCityContext,
    required this.canAddDiscovery,
    required this.canAddDiscoveryToPlannedDay,
    required this.onAddDiscovery,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onEarlier,
    required this.onLater,
    required this.onOptimize,
    required this.onOpenMap,
    required this.onRemove,
    required this.isSaving,
    required this.canOptimize,
    this.optimization,
  });

  final int dayNumber;
  final String dateLabel;
  final List<SavedTripItineraryStop> stops;
  final int tripDayCount;
  final bool showCityContext;
  final bool canAddDiscovery;
  final bool canAddDiscoveryToPlannedDay;
  final VoidCallback onAddDiscovery;

  final Future<void> Function(SavedTripItineraryStop) onPreviousDay;
  final Future<void> Function(SavedTripItineraryStop) onNextDay;
  final Future<void> Function(SavedTripItineraryStop) onEarlier;
  final Future<void> Function(SavedTripItineraryStop) onLater;
  final Future<void> Function() onOptimize;
  final VoidCallback onOpenMap;
  final Future<void> Function(SavedTripItineraryStop) onRemove;
  final bool isSaving;
  final bool canOptimize;
  final ItineraryRouteOptimization? optimization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              child: Text('$dayNumber'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${context.l10n.text('day')} $dayNumber • $dateLabel',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              context.l10n
                  .text('itineraryStopCount')
                  .replaceAll('{count}', stops.length.toString()),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        if (showCityContext && stops.isNotEmpty) ...[
          const SizedBox(height: 8),
          _DayCityContext(
            cities: ItineraryDayCitySummaryBuilder.build(stops),
          ),
        ],
        if (stops.isNotEmpty) ...[
          const SizedBox(height: 10),
          _DayPlanningCapacityBar(
            stopCount: stops.length,
            maxStopsPerDay: GenerateSavedTripItinerary.maxStopsPerDay,
            canAddDiscovery: canAddDiscoveryToPlannedDay,
            onAddDiscovery: onAddDiscovery,
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: stops.isEmpty ? null : onOpenMap,
                icon: const Icon(Icons.map_outlined),
                label: Text(context.l10n.text('routeMap')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: !canOptimize || isSaving
                    ? null
                    : () async => onOptimize(),
                icon: const Icon(Icons.auto_fix_high),
                label: Text(context.l10n.text('optimizeRoute')),
              ),
            ),
          ],
        ),
        if (stops.length >= 2 && !canOptimize) ...[
          const SizedBox(height: 8),
          _CoordinateSafetyNotice(),
        ],
        if (optimization != null) ...[
          const SizedBox(height: 8),
          _OptimizationSummary(optimization: optimization!),
        ],
        const SizedBox(height: 8),
        if (stops.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.event_available_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.text('freeDay'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (canAddDiscovery)
                          Text(
                            context.l10n.text('freeDayAddDiscoveryHint'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (canAddDiscovery)
                    FilledButton.tonalIcon(
                      onPressed: onAddDiscovery,
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: Text(context.l10n.text('addDiscovery')),
                    ),
                ],
              ),
            ),
          )
        else
          ...stops.map(
            (stop) => _ItineraryStopCard(
              stop: stop,
              tripDayCount: tripDayCount,
              showCityContext: showCityContext,
              isSaving: isSaving,
              onEarlier: () => onEarlier(stop),
              onLater: () => onLater(stop),
              onPreviousDay: () => onPreviousDay(stop),
              onNextDay: () => onNextDay(stop),
              onRemove: () => onRemove(stop),
              onOpenDetails: () => context.push(
                AppRoutes.contentDetail(stop.content.id),
                extra: stop.content,
              ),
            ),
          ),
      ],
    );
  }
}

class _ItineraryStopCard extends StatelessWidget {
  const _ItineraryStopCard({
    required this.stop,
    required this.tripDayCount,
    required this.showCityContext,
    required this.isSaving,
    required this.onEarlier,
    required this.onLater,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onRemove,
    required this.onOpenDetails,
  });

  final SavedTripItineraryStop stop;
  final int tripDayCount;
  final bool showCityContext;
  final bool isSaving;
  final VoidCallback onEarlier;
  final VoidCallback onLater;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onRemove;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final images = stop.content.allImageUrls;
    final imageUrl = images.isEmpty ? null : images.first;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        leading: Container(
          width: 62,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule_rounded, size: 17),
              const SizedBox(height: 2),
              Text(
                stop.timeLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          stop.content.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showCityContext &&
                  stop.content.cityName.trim().isNotEmpty) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_city_outlined, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        stop.content.cityName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
              ],
              Text(
                stop.content.shortDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          if (imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: double.infinity,
                height: 128,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    child: const Icon(Icons.image_outlined, size: 34),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenDetails,
                  icon: const Icon(Icons.info_outline_rounded),
                  label: Text(context.l10n.text('openDetails')),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<_ItineraryStopAction>(
                enabled: !isSaving,
                tooltip: context.l10n.text('editStop'),
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.tune_rounded),
                onSelected: (action) {
                  switch (action) {
                    case _ItineraryStopAction.earlier:
                      onEarlier();
                    case _ItineraryStopAction.later:
                      onLater();
                    case _ItineraryStopAction.previousDay:
                      onPreviousDay();
                    case _ItineraryStopAction.nextDay:
                      onNextDay();
                    case _ItineraryStopAction.remove:
                      onRemove();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _ItineraryStopAction.earlier,
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.schedule_rounded),
                      title: Text('-30 ${context.l10n.text('min')}'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _ItineraryStopAction.later,
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.schedule_rounded),
                      title: Text('+30 ${context.l10n.text('min')}'),
                    ),
                  ),
                  if (stop.dayIndex > 0)
                    PopupMenuItem(
                      value: _ItineraryStopAction.previousDay,
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.arrow_back_rounded),
                        title: Text(context.l10n.text('previousDay')),
                      ),
                    ),
                  if (stop.dayIndex < tripDayCount - 1)
                    PopupMenuItem(
                      value: _ItineraryStopAction.nextDay,
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.arrow_forward_rounded),
                        title: Text(context.l10n.text('nextDay')),
                      ),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: _ItineraryStopAction.remove,
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.delete_outline_rounded),
                      title: Text(context.l10n.text('remove')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _ItineraryStopAction {
  earlier,
  later,
  previousDay,
  nextDay,
  remove,
}

class _CoordinateSafetyNotice extends StatelessWidget {
  const _CoordinateSafetyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_searching_rounded, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.text('routeExactCoordinatesRequired'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptimizationSummary extends StatelessWidget {
  const _OptimizationSummary({
    required this.optimization,
  });

  final ItineraryRouteOptimization optimization;

  String _distance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final saved = optimization.savedMeters;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        child: Row(
          children: [
            const Icon(Icons.route_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${context.l10n.text('routeReducedFrom')} '
                '${_distance(optimization.distanceBeforeMeters)} '
                '${context.l10n.text('to')} '
                '${_distance(optimization.distanceAfterMeters)}',
              ),
            ),
            if (saved > 20)
              Text(
                '-${optimization.improvementPercent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
