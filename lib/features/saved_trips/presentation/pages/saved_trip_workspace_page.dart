import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_error_presenter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../explore/domain/entities/explore_content.dart';
import '../../../explore/domain/entities/explore_category.dart';
import '../../../explore/domain/repositories/explore_repository.dart';
import '../../../offline/presentation/providers/offline_city_pack_provider.dart';
import '../../../subscription/domain/entities/subscription_entitlement.dart';
import '../../../subscription/presentation/widgets/premium_gate.dart';
import '../providers/saved_trips_provider.dart';
import '../providers/saved_trip_itinerary_provider.dart';
import '../../domain/services/vacation_plan_progress.dart';
import '../../domain/services/country_plan_city_summary.dart';
import '../../domain/services/country_plan_city_filter.dart';
import '../../domain/services/vacation_discovery_plan_filter.dart';
import '../../domain/services/vacation_category_progress.dart';
import '../../domain/services/vacation_category_filter.dart';
import '../widgets/create_saved_trip_dialog.dart';
import '../../domain/entities/saved_trip_draft.dart';

class SavedTripWorkspacePage extends StatefulWidget {
  const SavedTripWorkspacePage({
    required this.tripId,
    super.key,
  });

  final String tripId;

  @override
  State<SavedTripWorkspacePage> createState() =>
      _SavedTripWorkspacePageState();
}

class _SavedTripWorkspacePageState
    extends State<SavedTripWorkspacePage> {
  List<ExploreContent>? _cityContents;
  String? _loadedLanguage;
  String? _loadError;
  int _loadRequestId = 0;
  String? _countryCityFilter;
  VacationDiscoveryPlanFilter _discoveryPlanFilter =
      VacationDiscoveryPlanFilter.all;
  ExploreCategory? _categoryFilter;

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

  Future<void> _load(String languageCode) async {
    final requestId = ++_loadRequestId;
    final tripId = widget.tripId;

    if (mounted) {
      setState(() {
        _loadError = null;
        _cityContents = null;
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
      final destinationContents = all
          .where(
            (item) =>
                item.countryCode.toLowerCase() == country &&
                (city.isEmpty || item.cityName.toLowerCase() == city),
          )
          .toList(growable: false);

      setState(() {
        _cityContents = destinationContents;
        _loadError = null;
      });

      await context.read<SavedTripItineraryProvider>().load(
            tripId: trip.id,
            cityContents: destinationContents,
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
  void didUpdateWidget(covariant SavedTripWorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tripId == widget.tripId) return;

    _loadRequestId++;
    _cityContents = null;
    _loadError = null;
    _countryCityFilter = null;
    _discoveryPlanFilter = VacationDiscoveryPlanFilter.all;
    _categoryFilter = null;

    final language =
        _loadedLanguage ?? Localizations.localeOf(context).languageCode;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _load(language),
    );
  }

  @override
  void dispose() {
    _loadRequestId++;
    super.dispose();
  }

  String _date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<void> _downloadOffline({
    required String countryCode,
    required String cityName,
  }) async {
    if (!PremiumGate.allowOrOpenPaywall(
      context,
      PremiumFeature.offlineCityPacks,
    )) {
      return;
    }

    final language = Localizations.localeOf(context).languageCode;

    try {
      await context.read<OfflineCityPackProvider>().download(
            countryCode: countryCode,
            cityName: cityName,
            languageCode: language,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('offlinePackReady'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorPresenter.message(context, error),
          ),
        ),
      );
    }
  }


Future<void> _editTrip() async {
  final trips = context.read<SavedTripsProvider>();
  final trip = trips.byId(widget.tripId);
  if (trip == null) return;

  final draft = await showDialog<SavedTripDraft>(
    context: context,
    builder: (_) => CreateSavedTripDialog(existingTrip: trip),
  );

  if (draft == null || !mounted) return;

  final updated = await trips.update(
    tripId: trip.id,
    draft: draft,
  );

  if (!mounted) return;

  if (updated == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppErrorPresenter.message(context, trips.errorMessage),
        ),
      ),
    );
    return;
  }

  await _load(Localizations.localeOf(context).languageCode);

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.l10n.text('tripUpdated'))),
  );
}

Future<void> _deleteTrip() async {
  final trips = context.read<SavedTripsProvider>();
  final trip = trips.byId(widget.tripId);
  if (trip == null) return;

  final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.text('deleteTrip')),
          content: Text(context.l10n.text('deleteTripConfirmation')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.text('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.text('delete')),
            ),
          ],
        ),
      ) ??
      false;

  if (!confirmed || !mounted) return;

  final deleted = await trips.deleteSafely(trip.id);
  if (!mounted) return;

  if (!deleted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppErrorPresenter.message(context, trips.errorMessage),
        ),
      ),
    );
    return;
  }

  context.pop();
}

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<SavedTripsProvider>();
    final itinerary = context.watch<SavedTripItineraryProvider>();
    final trip = trips.byId(widget.tripId);
    final cityContents = _cityContents;

    if (trip == null &&
        (trips.isLoading || cityContents == null && _loadError == null)) {
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

    final countryWide = trip.cityName.trim().isEmpty;
    final cityFilteredContents = _cityContents == null
        ? null
        : CountryPlanCityFilter.apply(
            contents: _cityContents!,
            cityName: countryWide ? _countryCityFilter : null,
          );
    final categoryFilteredContents = cityFilteredContents == null
        ? null
        : VacationCategoryFilter.apply(
            contents: cityFilteredContents,
            category: _categoryFilter,
          );
    final filteredContents = categoryFilteredContents == null
        ? null
        : VacationDiscoveryPlanFilterPolicy.apply(
            contents: categoryFilteredContents,
            savedContentIds: trip.contentIds,
            itineraryStops: itinerary.stops,
            filter: _discoveryPlanFilter,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.name),
        actions: [
          IconButton(
            tooltip: context.l10n.text('editTrip'),
            onPressed: trips.isPending(trip.id) ? null : _editTrip,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: context.l10n.text('delete'),
            onPressed: trips.isPending(trip.id) ? null : _deleteTrip,
            icon: trips.isPending(trip.id)
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    trip.cityName.trim().isEmpty
                        ? trip.countryName
                        : '${trip.cityName}, ${trip.countryName}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_date(trip.startDate)} → '
                    '${_date(trip.endDate)} • '
                    '${trip.dayCount} ${context.l10n.text('days')}',
                  ),
                  if (trip.notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(trip.notes),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _VacationPlanSummary(
            location: trip.cityName.trim().isEmpty
                ? trip.countryName
                : '${trip.cityName}, ${trip.countryName}',
            dateRange:
                '${_date(trip.startDate)} → ${_date(trip.endDate)}',
            dayCount: trip.dayCount,
            savedCount: trip.contentIds.length,
          ),
          const SizedBox(height: 12),
          _PlanProgressCard(
            progress: VacationPlanProgress.from(
              savedCount: trip.contentIds.length,
              totalDayCount: trip.dayCount,
              stops: itinerary.stops,
              unresolvedStopCount: itinerary.unresolvedStopCount,
            ),
            isLoading: itinerary.isLoading,
            onAddDiscoveries: () => context.go(AppRoutes.home),
            onOpenItinerary: () {
              if (!PremiumGate.allowOrOpenPaywall(
                context,
                PremiumFeature.advancedTripPlanner,
              )) {
                return;
              }
              context.push(
                AppRoutes.savedTripItineraryFor(trip.id),
              );
            },
          ),
          if (trip.cityName.trim().isEmpty &&
              _cityContents != null) ...[
            const SizedBox(height: 12),
            _CountryPlanCitiesCard(
              summaries: CountryPlanCitySummaryBuilder.build(
                destinationContents: _cityContents!,
                savedContentIds: trip.contentIds,
                itineraryStops: itinerary.stops,
              ),
              selectedCity: _countryCityFilter,
              onSelectCity: (cityName) {
                setState(() {
                  _countryCityFilter =
                      _countryCityFilter == cityName ? null : cityName;
                });
              },
            ),
          ],
          if (trip.cityName.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              context.l10n.text('destinationTools'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(context.l10n.text('destinationToolsSubtitle')),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _ToolCard(
                  icon: Icons.auto_awesome,
                  title: context.l10n.text('travelAssistant'),
                  onTap: () {
                    if (!PremiumGate.allowOrOpenPaywall(
                      context,
                      PremiumFeature.travelAssistant,
                    )) {
                      return;
                    }
                    context.push(
                      '${AppRoutes.travelAssistant}'
                      '?city=${Uri.encodeComponent(trip.cityName)}',
                    );
                  },
                ),
                _ToolCard(
                  icon: Icons.download_outlined,
                  title: context.l10n.text('offlineCityPacks'),
                  onTap: () => _downloadOffline(
                    countryCode: trip.countryCode,
                    cityName: trip.cityName,
                  ),
                ),
                _ToolCard(
                  icon: Icons.flight_land,
                  title: context.l10n.text('first24Hours'),
                  onTap: () => context.push(
                    AppRoutes.arrivalGuideFor(
                      countryCode: trip.countryCode,
                      cityName: trip.cityName,
                    ),
                  ),
                ),
                _ToolCard(
                  icon: Icons.public,
                  title: context.l10n.text('cultureGuide'),
                  onTap: () => context.push(
                    AppRoutes.cultureGuideFor(
                      countryCode: trip.countryCode,
                      cityName: trip.cityName,
                    ),
                  ),
                ),
                _ToolCard(
                  icon: Icons.map_outlined,
                  title: context.l10n.text('discoverCity'),
                  onTap: () => context.push(
                    AppRoutes.cityDetail(
                      countryCode: trip.countryCode,
                      cityName: trip.cityName,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.text('vacationDiscoveries'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  context.l10n
                      .text('savedCount')
                      .replaceAll(
                        '{count}',
                        trip.contentIds.length.toString(),
                      ),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            trip.cityName.trim().isEmpty
                ? context.l10n.text('vacationDiscoveriesCountrySubtitle')
                : context.l10n.text('vacationDiscoveriesCitySubtitle'),
          ),
          if (countryWide && _countryCityFilter != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n
                        .text('countryPlanFilteringCity')
                        .replaceAll('{city}', _countryCityFilter!),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _countryCityFilter = null),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(context.l10n.text('showAllCities')),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          if (cityFilteredContents != null &&
              cityFilteredContents.isNotEmpty) ...[
            _VacationCategoryProgressCard(
              items: VacationCategoryProgressBuilder.build(
                contents: cityFilteredContents,
                savedContentIds: trip.contentIds,
                itineraryStops: itinerary.stops,
              ),
              selectedCategory: _categoryFilter,
              onSelectCategory: (category) {
                setState(() {
                  _categoryFilter =
                      _categoryFilter == category ? null : category;
                });
              },
            ),
            const SizedBox(height: 10),
          ],
          if (_categoryFilter != null) ...[
            _ActiveCategoryFilterBanner(
              category: _categoryFilter!,
              onClear: () => setState(() => _categoryFilter = null),
            ),
            const SizedBox(height: 10),
          ],
          _DiscoveryPlanFilterBar(
            selected: _discoveryPlanFilter,
            savedCount: trip.contentIds.length,
            unscheduledCount: VacationPlanProgress.from(
              savedCount: trip.contentIds.length,
              totalDayCount: trip.dayCount,
              stops: itinerary.stops,
              unresolvedStopCount: itinerary.unresolvedStopCount,
            ).unscheduledCount,
            onChanged: (value) {
              setState(() => _discoveryPlanFilter = value);
            },
          ),
          const SizedBox(height: 10),
          if (filteredContents == null)
            const Center(child: CircularProgressIndicator())
          else if (filteredContents.isEmpty)
            _DiscoveryFilterEmptyState(
              filter: _discoveryPlanFilter,
              onShowAll: () {
                setState(() {
                  _discoveryPlanFilter = VacationDiscoveryPlanFilter.all;
                });
              },
              onDiscover: () => context.go(AppRoutes.home),
            )
          else ...[
            _TripDiscoverySection(
              title: context.l10n.text('places'),
              icon: Icons.place_outlined,
              items: filteredContents
                  .where((item) => item.category == ExploreCategory.place)
                  .toList(growable: false),
              tripId: trip.id,
              selectedIds: trip.contentIds,
            ),
            _TripDiscoverySection(
              title: context.l10n.text('food'),
              icon: Icons.restaurant_outlined,
              items: filteredContents
                  .where((item) => item.category == ExploreCategory.food)
                  .toList(growable: false),
              tripId: trip.id,
              selectedIds: trip.contentIds,
            ),
            _TripDiscoverySection(
              title: context.l10n.text('drinks'),
              icon: Icons.local_cafe_outlined,
              items: filteredContents
                  .where((item) => item.category == ExploreCategory.drink)
                  .toList(growable: false),
              tripId: trip.id,
              selectedIds: trip.contentIds,
            ),
            _TripDiscoverySection(
              title: context.l10n.text('snacks'),
              icon: Icons.cookie_outlined,
              items: filteredContents
                  .where((item) => item.category == ExploreCategory.snack)
                  .toList(growable: false),
              tripId: trip.id,
              selectedIds: trip.contentIds,
            ),
            _TripDiscoverySection(
              title: context.l10n.text('culture'),
              icon: Icons.museum_outlined,
              items: filteredContents
                  .where((item) => item.category == ExploreCategory.culture)
                  .toList(growable: false),
              tripId: trip.id,
              selectedIds: trip.contentIds,
            ),
            _TripDiscoverySection(
              title: context.l10n.text('fruit'),
              icon: Icons.eco_outlined,
              items: filteredContents
                  .where((item) => item.category == ExploreCategory.fruit)
                  .toList(growable: false),
              tripId: trip.id,
              selectedIds: trip.contentIds,
            ),
          ],
          const SizedBox(height: 24),
          _BuildItineraryCard(
            savedCount: trip.contentIds.length,
            onOpenItinerary: () {
              if (!PremiumGate.allowOrOpenPaywall(
                context,
                PremiumFeature.advancedTripPlanner,
              )) {
                return;
              }
              context.push(
                AppRoutes.savedTripItineraryFor(trip.id),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActiveCategoryFilterBanner extends StatelessWidget {
  const _ActiveCategoryFilterBanner({
    required this.category,
    required this.onClear,
  });

  final ExploreCategory category;
  final VoidCallback onClear;

  String _label(BuildContext context) {
    switch (category) {
      case ExploreCategory.place:
        return context.l10n.text('places');
      case ExploreCategory.food:
        return context.l10n.text('food');
      case ExploreCategory.drink:
        return context.l10n.text('drinks');
      case ExploreCategory.snack:
        return context.l10n.text('snacks');
      case ExploreCategory.culture:
        return context.l10n.text('culture');
      case ExploreCategory.fruit:
        return context.l10n.text('fruit');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n
                .text('planCategoryFiltering')
                .replaceAll('{category}', _label(context)),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        TextButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.close_rounded, size: 18),
          label: Text(context.l10n.text('planCategoryShowAll')),
        ),
      ],
    );
  }
}

class _VacationCategoryProgressCard extends StatelessWidget {
  const _VacationCategoryProgressCard({
    required this.items,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  final List<VacationCategoryProgress> items;
  final ExploreCategory? selectedCategory;
  final ValueChanged<ExploreCategory> onSelectCategory;

  String _label(BuildContext context, ExploreCategory category) {
    switch (category) {
      case ExploreCategory.place:
        return context.l10n.text('places');
      case ExploreCategory.food:
        return context.l10n.text('food');
      case ExploreCategory.drink:
        return context.l10n.text('drinks');
      case ExploreCategory.snack:
        return context.l10n.text('snacks');
      case ExploreCategory.culture:
        return context.l10n.text('culture');
      case ExploreCategory.fruit:
        return context.l10n.text('fruit');
    }
  }

  IconData _icon(ExploreCategory category) {
    switch (category) {
      case ExploreCategory.place:
        return Icons.place_outlined;
      case ExploreCategory.food:
        return Icons.restaurant_outlined;
      case ExploreCategory.drink:
        return Icons.local_cafe_outlined;
      case ExploreCategory.snack:
        return Icons.cookie_outlined;
      case ExploreCategory.culture:
        return Icons.museum_outlined;
      case ExploreCategory.fruit:
        return Icons.eco_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.text('planCategoryProgressTitle'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(context.l10n.text('planCategoryProgressSubtitle')),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in items)
                  InkWell(
                    onTap: () => onSelectCategory(item.category),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selectedCategory == item.category ||
                                item.isComplete
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: selectedCategory == item.category
                            ? Border.all(
                                color: theme.colorScheme.primary,
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isComplete
                              ? Icons.check_circle_outline_rounded
                              : _icon(item.category),
                          size: 17,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _label(context, item.category),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${item.scheduledCount}/${item.savedCount}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.text('planCategoryProgressLegend'),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryPlanFilterBar extends StatelessWidget {
  const _DiscoveryPlanFilterBar({
    required this.selected,
    required this.savedCount,
    required this.unscheduledCount,
    required this.onChanged,
  });

  final VacationDiscoveryPlanFilter selected;
  final int savedCount;
  final int unscheduledCount;
  final ValueChanged<VacationDiscoveryPlanFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            selected: selected == VacationDiscoveryPlanFilter.all,
            label: Text(context.l10n.text('planFilterAll')),
            onSelected: (_) => onChanged(VacationDiscoveryPlanFilter.all),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            selected: selected == VacationDiscoveryPlanFilter.saved,
            label: Text(
              context.l10n
                  .text('planFilterSaved')
                  .replaceAll('{count}', savedCount.toString()),
            ),
            onSelected: (_) => onChanged(VacationDiscoveryPlanFilter.saved),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            selected: selected == VacationDiscoveryPlanFilter.unscheduled,
            label: Text(
              context.l10n
                  .text('planFilterUnscheduled')
                  .replaceAll('{count}', unscheduledCount.toString()),
            ),
            onSelected: (_) =>
                onChanged(VacationDiscoveryPlanFilter.unscheduled),
          ),
        ],
      ),
    );
  }
}

class _DiscoveryFilterEmptyState extends StatelessWidget {
  const _DiscoveryFilterEmptyState({
    required this.filter,
    required this.onShowAll,
    required this.onDiscover,
  });

  final VacationDiscoveryPlanFilter filter;
  final VoidCallback onShowAll;
  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    if (filter == VacationDiscoveryPlanFilter.all) {
      return _VacationDiscoveryEmptyState(onDiscover: onDiscover);
    }

    final isUnscheduled =
        filter == VacationDiscoveryPlanFilter.unscheduled;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(
              isUnscheduled
                  ? Icons.event_available_outlined
                  : Icons.bookmark_border_rounded,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.text(
                isUnscheduled
                    ? 'planFilterNoUnscheduled'
                    : 'planFilterNoSaved',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onShowAll,
              child: Text(context.l10n.text('planFilterShowAll')),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanProgressCard extends StatelessWidget {
  const _PlanProgressCard({
    required this.progress,
    required this.isLoading,
    required this.onAddDiscoveries,
    required this.onOpenItinerary,
  });

  final VacationPlanProgress progress;
  final bool isLoading;
  final VoidCallback onAddDiscoveries;
  final VoidCallback onOpenItinerary;

  String _nextActionLabel(BuildContext context) {
    switch (progress.nextAction) {
      case VacationPlanNextAction.addDiscoveries:
        return context.l10n.text('planNextAddDiscoveries');
      case VacationPlanNextAction.buildItinerary:
        return context.l10n.text('planNextBuildItinerary');
      case VacationPlanNextAction.continueItinerary:
        return context.l10n.text('planNextContinueItinerary');
      case VacationPlanNextAction.reviewPlan:
        return context.l10n.text('planNextReviewPlan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionIsDiscover =
        progress.nextAction == VacationPlanNextAction.addDiscoveries;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.text('planProgressTitle'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(context.l10n.text('planProgressSubtitle')),
            const SizedBox(height: 16),
            _PlanProgressRow(
              label: context.l10n.text('planProgressScheduled'),
              value: '${progress.scheduledCount}/${progress.savedCount}',
              ratio: progress.scheduleRatio,
            ),
            const SizedBox(height: 12),
            _PlanProgressRow(
              label: context.l10n.text('planProgressDays'),
              value: '${progress.plannedDayCount}/${progress.totalDayCount}',
              ratio: progress.dayCoverageRatio,
            ),
            if (progress.unscheduledCount > 0) ...[
              const SizedBox(height: 10),
              Text(
                context.l10n
                    .text('planProgressUnscheduled')
                    .replaceAll('{count}', progress.unscheduledCount.toString()),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (progress.unresolvedStopCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n
                    .text('planProgressUnresolved')
                    .replaceAll(
                      '{count}',
                      progress.unresolvedStopCount.toString(),
                    ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isLoading
                  ? null
                  : actionIsDiscover
                      ? onAddDiscoveries
                      : onOpenItinerary,
              icon: Icon(
                actionIsDiscover
                    ? Icons.explore_outlined
                    : Icons.calendar_month_outlined,
              ),
              label: Text(_nextActionLabel(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanProgressRow extends StatelessWidget {
  const _PlanProgressRow({
    required this.label,
    required this.value,
    required this.ratio,
  });

  final String label;
  final String value;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: ratio),
      ],
    );
  }
}

class _CountryPlanCitiesCard extends StatelessWidget {
  const _CountryPlanCitiesCard({
    required this.summaries,
    required this.selectedCity,
    required this.onSelectCity,
  });

  final List<CountryPlanCitySummary> summaries;
  final String? selectedCity;
  final ValueChanged<String> onSelectCity;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final visible = summaries.take(8).toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_city_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.text('countryPlanCitiesTitle'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(context.l10n.text('countryPlanCitiesSubtitle')),
            const SizedBox(height: 14),
            for (var index = 0; index < visible.length; index++) ...[
              _CountryPlanCityRow(
                summary: visible[index],
                selected: selectedCity == visible[index].cityName,
                onTap: () => onSelectCity(visible[index].cityName),
              ),
              if (index != visible.length - 1) const Divider(height: 20),
            ],
            if (summaries.length > visible.length) ...[
              const SizedBox(height: 10),
              Text(
                context.l10n
                    .text('countryPlanMoreCities')
                    .replaceAll(
                      '{count}',
                      (summaries.length - visible.length).toString(),
                    ),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountryPlanCityRow extends StatelessWidget {
  const _CountryPlanCityRow({
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  final CountryPlanCitySummary summary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPlan = summary.scheduledCount > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            hasPlan ? Icons.check_rounded : Icons.location_on_outlined,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.cityName,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                context.l10n
                    .text('countryPlanCityStats')
                    .replaceAll('{saved}', summary.savedCount.toString())
                    .replaceAll(
                      '{scheduled}',
                      summary.scheduledCount.toString(),
                    )
                    .replaceAll(
                      '{available}',
                      summary.availableCount.toString(),
                    ),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (summary.plannedDayCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              context.l10n
                  .text('countryPlanCityDays')
                  .replaceAll(
                    '{count}',
                    summary.plannedDayCount.toString(),
                  ),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
        ),
      ),
    );
  }
}

class _VacationDiscoveryEmptyState extends StatelessWidget {
  const _VacationDiscoveryEmptyState({
    required this.onDiscover,
  });

  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.travel_explore_rounded, size: 38),
          const SizedBox(height: 10),
          Text(
            context.l10n.text('vacationNoDiscoveriesTitle'),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.text('vacationNoDiscoveriesSubtitle'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: onDiscover,
            icon: const Icon(Icons.explore_outlined),
            label: Text(context.l10n.text('exploreInstead')),
          ),
        ],
      ),
    );
  }
}

class _VacationPlanSummary extends StatelessWidget {
  const _VacationPlanSummary({
    required this.location,
    required this.dateRange,
    required this.dayCount,
    required this.savedCount,
  });

  final String location;
  final String dateRange;
  final int dayCount;
  final int savedCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.travel_explore_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$dateRange • '
                    '${context.l10n.text('tripDays').replaceAll('{count}', dayCount.toString())}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                context.l10n
                    .text('savedCount')
                    .replaceAll('{count}', savedCount.toString()),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildItineraryCard extends StatelessWidget {
  const _BuildItineraryCard({
    required this.savedCount,
    required this.onOpenItinerary,
  });

  final int savedCount;
  final VoidCallback onOpenItinerary;

  @override
  Widget build(BuildContext context) {
    final ready = savedCount > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                child: Icon(Icons.route_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ready
                      ? context.l10n.text('vacationItineraryReadyTitle')
                      : context.l10n.text('vacationItineraryEmptyTitle'),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ready
                ? context.l10n
                    .text('vacationItineraryReadySubtitle')
                    .replaceAll('{count}', savedCount.toString())
                : context.l10n.text('vacationItineraryEmptySubtitle'),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: ready ? onOpenItinerary : null,
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(
                ready
                    ? context.l10n.text('buildDayByDayPlan')
                    : context.l10n.text('saveDiscoveriesFirst'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripDiscoverySection extends StatelessWidget {
  const _TripDiscoverySection({
    required this.title,
    required this.icon,
    required this.items,
    required this.tripId,
    required this.selectedIds,
  });

  final String title;
  final IconData icon;
  final List<ExploreContent> items;
  final String tripId;
  final List<String> selectedIds;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                context.l10n
                    .text('discoveryCount')
                    .replaceAll('{count}', items.length.toString()),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 246,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _TripDiscoveryCard(
                  content: item,
                  tripId: tripId,
                  selected: selectedIds.contains(item.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TripDiscoveryCard extends StatelessWidget {
  const _TripDiscoveryCard({
    required this.content,
    required this.tripId,
    required this.selected,
  });

  final ExploreContent content;
  final String tripId;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<SavedTripsProvider>();
    final pending = trips.isContentPending(
      tripId: tripId,
      contentId: content.id,
    );
    final tripWritePending = trips.isPending(tripId);
    final imageUrl =
        content.allImageUrls.isEmpty ? null : content.allImageUrls.first;

    return SizedBox(
      width: 190,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(
            AppRoutes.contentDetail(content.id),
            extra: content,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 108,
                    width: double.infinity,
                    child: imageUrl == null
                        ? Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child: const Icon(
                              Icons.image_outlined,
                              size: 34,
                            ),
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: const Icon(
                                Icons.image_outlined,
                                size: 34,
                              ),
                            ),
                          ),
                  ),
                  if (selected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              context.l10n.text('saved'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        content.shortDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    content.cityName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_outward_rounded,
                                  size: 13,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: selected
                                ? context.l10n.text('remove')
                                : context.l10n.text('save'),
                            onPressed: tripWritePending
                                ? null
                                : () async {
                                    final ok = await trips.toggleContent(
                                      tripId: tripId,
                                      contentId: content.id,
                                    );

                                    if (!context.mounted || ok) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          trips.errorCode ==
                                                  'content_not_synced_to_supabase'
                                              ? context.l10n.text(
                                                  'savedTripCatalogSyncRequired',
                                                )
                                              : AppErrorPresenter.message(
                                                  context,
                                                  trips.errorMessage,
                                                ),
                                        ),
                                      ),
                                    );
                                  },
                            icon: pending
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    selected
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
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
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}