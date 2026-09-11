import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_error_presenter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/saved_trip.dart';
import '../../domain/services/saved_trip_lifecycle.dart';
import '../providers/saved_trips_provider.dart';

class SavedTripsPage extends StatefulWidget {
  const SavedTripsPage({
    this.initialCountryCode,
    this.initialCountryName,
    this.initialCityName,
    super.key,
  });

  final String? initialCountryCode;
  final String? initialCountryName;
  final String? initialCityName;

  @override
  State<SavedTripsPage> createState() => _SavedTripsPageState();
}

class _SavedTripsPageState extends State<SavedTripsPage> {
  bool _handledInitialCreate = false;

  String get _currentLocation {
    final countryCode = (widget.initialCountryCode ?? '').trim();
    final countryName = (widget.initialCountryName ?? '').trim();
    final cityName = (widget.initialCityName ?? '').trim();

    if (countryCode.isEmpty || countryName.isEmpty || cityName.isEmpty) {
      return AppRoutes.savedTrips;
    }

    return AppRoutes.savedTripsForCity(
      countryCode: countryCode,
      countryName: countryName,
      cityName: cityName,
    );
  }

  void _openLogin() {
    context.push(AppRoutes.loginFor(_currentLocation));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_handledInitialCreate) return;
    _handledInitialCreate = true;

    if ((widget.initialCityName ?? '').trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _create());
    }
  }

  void _create() {
    final auth = context.read<AuthProvider>();
    final plannerLocation = AppRoutes.vacationPlannerFor(
      countryCode: widget.initialCountryCode,
      countryName: widget.initialCountryName,
      cityName: widget.initialCityName,
    );

    if (auth.isGuest) {
      context.push(AppRoutes.loginFor(plannerLocation));
      return;
    }

    context.push(plannerLocation);
  }


  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<SavedTripsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('planVacation')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.text('planVacation')),
      ),
      body: auth.isGuest
          ? Center(
              child: FilledButton.icon(
                onPressed: _openLogin,
                icon: const Icon(Icons.login),
                label: Text(context.l10n.text('savedTripsLogin')),
              ),
            )
          : provider.isLoading && provider.trips.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : provider.errorMessage != null && provider.trips.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off_rounded, size: 56),
                            const SizedBox(height: 14),
                            Text(
                              context.l10n.text('tripsLoadFailed'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.l10n.text('tripsLoadFailedMessage'),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            FilledButton.tonalIcon(
                              onPressed: provider.refresh,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(context.l10n.text('retry')),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                  onRefresh: provider.refresh,
                  child: provider.trips.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 180),
                            Icon(
                              Icons.luggage_outlined,
                              size: 56,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.l10n.text('savedTripsEmpty'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                context.l10n.text('savedTripsEmptySubtitle'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Center(
                              child: FilledButton.icon(
                                onPressed: _create,
                                icon: const Icon(Icons.add_rounded),
                                label: Text(context.l10n.text('planVacation')),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            12,
                            16,
                            100,
                          ),
                          itemCount: provider.trips.length +
                              (provider.errorMessage != null ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            if (provider.errorMessage != null && index == 0) {
                              return _RefreshErrorCard(
                                message: AppErrorPresenter.message(
                                  context,
                                  provider.errorMessage,
                                ),
                                onRetry: provider.refresh,
                              );
                            }

                            final tripIndex =
                                index - (provider.errorMessage != null ? 1 : 0);
                            final trip = provider.trips[tripIndex];
                            final pending = provider.isPending(trip.id);

                            return _VacationTripCard(
                              trip: trip,
                              pending: pending,
                              onOpen: () => context.push(
                                AppRoutes.savedTripDetailFor(trip.id),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}



class _VacationTripCard extends StatelessWidget {
  const _VacationTripCard({
    required this.trip,
    required this.pending,
    required this.onOpen,
  });

  final SavedTrip trip;
  final bool pending;
  final VoidCallback onOpen;

  String _statusKey(SavedTripLifecycle lifecycle) {
    return switch (lifecycle) {
      SavedTripLifecycle.upcoming => 'tripStatusUpcoming',
      SavedTripLifecycle.active => 'tripStatusActive',
      SavedTripLifecycle.past => 'tripStatusPast',
    };
  }

  IconData _statusIcon(SavedTripLifecycle lifecycle) {
    return switch (lifecycle) {
      SavedTripLifecycle.upcoming => Icons.schedule_rounded,
      SavedTripLifecycle.active => Icons.explore_rounded,
      SavedTripLifecycle.past => Icons.check_circle_outline_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final lifecycle = savedTripLifecycle(
      startDate: trip.startDate,
      endDate: trip.endDate,
      now: DateTime.now(),
    );
    final destination = trip.cityName.trim().isEmpty
        ? trip.countryName
        : '${trip.cityName}, ${trip.countryName}';
    final dateFormatter = MaterialLocalizations.of(context);
    final dateRange =
        '${dateFormatter.formatMediumDate(trip.startDate)} – '
        '${dateFormatter.formatMediumDate(trip.endDate)}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: pending ? null : onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 17),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                destination,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _TripStatusBadge(
                    label: context.l10n.text(_statusKey(lifecycle)),
                    icon: _statusIcon(lifecycle),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                dateRange,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TripMetricChip(
                    icon: Icons.calendar_view_day_outlined,
                    label: context.l10n
                        .text('tripDayCount')
                        .replaceAll('{count}', '${trip.dayCount}'),
                  ),
                  _TripMetricChip(
                    icon: Icons.bookmark_outline_rounded,
                    label: context.l10n
                        .text('tripSavedCount')
                        .replaceAll('{count}', '${trip.contentIds.length}'),
                  ),
                  _TripMetricChip(
                    icon: trip.cityName.trim().isEmpty
                        ? Icons.public_rounded
                        : Icons.location_city_rounded,
                    label: context.l10n.text(
                      trip.cityName.trim().isEmpty
                          ? 'wholeCountry'
                          : 'citySelected',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.text('openVacationWorkspace'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (pending)
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripStatusBadge extends StatelessWidget {
  const _TripStatusBadge({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSecondaryContainer),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSecondaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripMetricChip extends StatelessWidget {
  const _TripMetricChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RefreshErrorCard extends StatelessWidget {
  const _RefreshErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
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
              onPressed: onRetry,
              child: Text(context.l10n.text('retry')),
            ),
          ],
        ),
      ),
    );
  }
}
