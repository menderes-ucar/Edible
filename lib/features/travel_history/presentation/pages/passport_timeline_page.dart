import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/entities/travel_visit.dart';
import '../providers/travel_history_provider.dart';

class PassportTimelinePage extends StatefulWidget {
  const PassportTimelinePage({super.key});

  @override
  State<PassportTimelinePage> createState() => _PassportTimelinePageState();
}

class _PassportTimelinePageState extends State<PassportTimelinePage> {
  bool _didLoad = false;
  int? _selectedYear;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didLoad) return;
    _didLoad = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<TravelHistoryProvider>().refresh();
      if (!mounted) return;

      final visits = _sorted(
        context.read<TravelHistoryProvider>().visits,
      );

      if (visits.isNotEmpty) {
        setState(() => _selectedYear = visits.first.visitDay.year);
      }
    });
  }

  List<TravelVisit> _sorted(List<TravelVisit> visits) {
    final copy = List<TravelVisit>.from(visits);
    copy.sort((a, b) {
      final byDay = b.visitDay.compareTo(a.visitDay);
      if (byDay != 0) return byDay;
      return b.firstSeenAt.compareTo(a.firstSeenAt);
    });
    return copy;
  }

  List<int> _years(List<TravelVisit> visits) {
    final years = visits.map((visit) => visit.visitDay.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }

  Future<void> _openMemory(TravelVisit visit) async {
    await context.push(AppRoutes.travelMemoryFor(visit.id));

    if (!mounted) return;
    await context.read<TravelHistoryProvider>().refresh();
  }

  void _surpriseMe(List<TravelVisit> visits) {
    if (visits.isEmpty) return;

    final index = Random.secure().nextInt(visits.length);
    _openMemory(visits[index]);
  }

  String _date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<TravelHistoryProvider>();
    final visits = _sorted(history.visits);
    final years = _years(visits);

    final activeYear = _selectedYear ??
        (years.isEmpty ? DateTime.now().year : years.first);

    final filtered = visits
        .where((visit) => visit.visitDay.year == activeYear)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('passportTimeline')),
        actions: [
          IconButton(
            tooltip: context.l10n.text('surpriseMemory'),
            onPressed: visits.isEmpty ? null : () => _surpriseMe(visits),
            icon: const Icon(Icons.casino_outlined),
          ),
        ],
      ),
      body: history.isLoading && visits.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : history.errorMessage != null && visits.isEmpty
              ? _TimelineState(
                  icon: Icons.cloud_off_rounded,
                  title: context.l10n.text('passportTimelineLoadFailed'),
                  message:
                      context.l10n.text('passportTimelineLoadFailedMessage'),
                  action: FilledButton.tonalIcon(
                    onPressed: history.refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.l10n.text('retry')),
                  ),
                )
              : visits.isEmpty
                  ? _TimelineState(
                      icon: Icons.auto_stories_outlined,
                      title: context.l10n.text('passportTimelineEmptyTitle'),
                      message: context.l10n.text('passportTimelineEmptyMessage'),
                    )
                  : RefreshIndicator(
                      onRefresh: history.refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        children: [
                          _TimelineHero(
                            countryCount: history.countryCount,
                            cityCount: history.cityCount,
                            travelDayCount: history.travelDayCount,
                            onSurprise: () => _surpriseMe(visits),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 42,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: years.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final year = years[index];

                                return ChoiceChip(
                                  label: Text('$year'),
                                  selected: activeYear == year,
                                  onSelected: (_) {
                                    setState(() => _selectedYear = year);
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '$activeYear',
                            style:
                                Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${filtered.length} '
                            '${context.l10n.text('timelineTravelDays')}',
                          ),
                          const SizedBox(height: 18),
                          ...List.generate(
                            filtered.length,
                            (index) {
                              final visit = filtered[index];

                              return _TimelineEntry(
                                visit: visit,
                                dateText: _date(visit.visitDay),
                                isFirst: index == 0,
                                isLast: index == filtered.length - 1,
                                onTap: () => _openMemory(visit),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _TimelineHero extends StatelessWidget {
  const _TimelineHero({
    required this.countryCount,
    required this.cityCount,
    required this.travelDayCount,
    required this.onSurprise,
  });

  final int countryCount;
  final int cityCount;
  final int travelDayCount;
  final VoidCallback onSurprise;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer,
            scheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.text('myTravelStory'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(context.l10n.text('passportTimelineSubtitle')),
          const SizedBox(height: 20),
          Row(
            children: [
              _HeroStat(
                value: countryCount,
                label: context.l10n.text('countries'),
              ),
              _HeroStat(
                value: cityCount,
                label: context.l10n.text('cities'),
              ),
              _HeroStat(
                value: travelDayCount,
                label: context.l10n.text('travelDays'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onSurprise,
              icon: const Icon(Icons.casino_outlined),
              label: Text(context.l10n.text('surpriseMemory')),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.value,
    required this.label,
  });

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.visit,
    required this.dateText,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final TravelVisit visit;
  final String dateText;
  final bool isFirst;
  final bool isLast;
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

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst
                        ? Colors.transparent
                        : scheme.outlineVariant,
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.surface,
                      width: 4,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : scheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _flag(visit.countryCode),
                            style: const TextStyle(fontSize: 27),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                visit.locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                dateText,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineState extends StatelessWidget {
  const _TimelineState({
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
            Text(message, textAlign: TextAlign.center),
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
