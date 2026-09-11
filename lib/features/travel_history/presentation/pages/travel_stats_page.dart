import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/travel_visit.dart';
import '../providers/travel_history_provider.dart';

class TravelStatsPage extends StatefulWidget {
  const TravelStatsPage({super.key});

  @override
  State<TravelStatsPage> createState() => _TravelStatsPageState();
}

class _TravelStatsPageState extends State<TravelStatsPage> {
  @override
  Widget build(BuildContext context) {
    final history = context.watch<TravelHistoryProvider>();
    final stats = _TravelStats.from(history.visits);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('travelStats')),
      ),
      body: history.isLoading && history.visits.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : history.errorMessage != null && history.visits.isEmpty
              ? _StateView(
                  icon: Icons.cloud_off_rounded,
                  title: context.l10n.text('travelStatsLoadFailed'),
                  message: context.l10n.text('travelStatsLoadFailedMessage'),
                  action: FilledButton.tonalIcon(
                    onPressed: history.refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.l10n.text('retry')),
                  ),
                )
              : history.visits.isEmpty
                  ? _StateView(
                      icon: Icons.insights_outlined,
                      title: context.l10n.text('travelStatsEmptyTitle'),
                      message: context.l10n.text('travelStatsEmptyMessage'),
                    )
                  : RefreshIndicator(
                      onRefresh: history.refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        children: [
                          _StatsHero(stats: stats),
                          const SizedBox(height: 22),
                          Text(
                            context.l10n.text('personalTravelRecords'),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 12),
                          _RecordGrid(stats: stats),
                          const SizedBox(height: 24),
                          Text(
                            context.l10n.text('travelByMonth'),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.l10n.text('travelByMonthSubtitle'),
                          ),
                          const SizedBox(height: 14),
                          _MonthDistribution(stats: stats),
                          const SizedBox(height: 24),
                          Text(
                            context.l10n.text('topTravelPlaces'),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 12),
                          _TopList(
                            title: context.l10n.text('topCountries'),
                            icon: Icons.public_outlined,
                            items: stats.topCountries,
                          ),
                          const SizedBox(height: 12),
                          _TopList(
                            title: context.l10n.text('topCities'),
                            icon: Icons.location_city_outlined,
                            items: stats.topCities,
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _TravelStats {
  const _TravelStats({
    required this.totalVisits,
    required this.countryCount,
    required this.cityCount,
    required this.firstVisit,
    required this.latestVisit,
    required this.busiestMonth,
    required this.busiestMonthCount,
    required this.longestMonthlyStreak,
    required this.monthCounts,
    required this.topCountries,
    required this.topCities,
  });

  final int totalVisits;
  final int countryCount;
  final int cityCount;
  final TravelVisit? firstVisit;
  final TravelVisit? latestVisit;
  final int busiestMonth;
  final int busiestMonthCount;
  final int longestMonthlyStreak;
  final Map<int, int> monthCounts;
  final List<_RankedPlace> topCountries;
  final List<_RankedPlace> topCities;

  factory _TravelStats.from(List<TravelVisit> visits) {
    if (visits.isEmpty) {
      return const _TravelStats(
        totalVisits: 0,
        countryCount: 0,
        cityCount: 0,
        firstVisit: null,
        latestVisit: null,
        busiestMonth: 1,
        busiestMonthCount: 0,
        longestMonthlyStreak: 0,
        monthCounts: {},
        topCountries: [],
        topCities: [],
      );
    }

    final sorted = List<TravelVisit>.from(visits)
      ..sort((a, b) => a.visitDay.compareTo(b.visitDay));

    final countryCounts = <String, int>{};
    final cityCounts = <String, int>{};
    final monthCounts = <int, int>{};
    final activeMonths = <int>{};

    for (final visit in visits) {
      final countryKey = visit.countryCode.trim().toUpperCase();
      if (countryKey.isNotEmpty) {
        countryCounts[countryKey] = (countryCounts[countryKey] ?? 0) + 1;
      }

      final city = visit.cityName.trim();
      if (city.isNotEmpty) {
        final cityKey = '$countryKey|$city';
        cityCounts[cityKey] = (cityCounts[cityKey] ?? 0) + 1;
      }

      monthCounts[visit.visitDay.month] =
          (monthCounts[visit.visitDay.month] ?? 0) + 1;

      activeMonths.add(visit.visitDay.year * 12 + visit.visitDay.month);
    }

    var busiestMonth = 1;
    var busiestCount = -1;
    for (var month = 1; month <= 12; month++) {
      final count = monthCounts[month] ?? 0;
      if (count > busiestCount) {
        busiestMonth = month;
        busiestCount = count;
      }
    }

    final sortedActiveMonths = activeMonths.toList()..sort();
    var longestStreak = sortedActiveMonths.isEmpty ? 0 : 1;
    var currentStreak = longestStreak;

    for (var i = 1; i < sortedActiveMonths.length; i++) {
      if (sortedActiveMonths[i] == sortedActiveMonths[i - 1] + 1) {
        currentStreak += 1;
      } else {
        currentStreak = 1;
      }

      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
    }

    List<_RankedPlace> rank(
      Map<String, int> source, {
      required bool city,
    }) {
      final entries = source.entries.toList()
        ..sort((a, b) {
          final byCount = b.value.compareTo(a.value);
          if (byCount != 0) return byCount;
          return a.key.compareTo(b.key);
        });

      return entries.take(5).map((entry) {
        if (!city) {
          return _RankedPlace(
            label: entry.key,
            count: entry.value,
          );
        }

        final parts = entry.key.split('|');
        return _RankedPlace(
          label: parts.length > 1 ? parts.sublist(1).join('|') : entry.key,
          suffix: parts.isNotEmpty ? parts.first : null,
          count: entry.value,
        );
      }).toList(growable: false);
    }

    return _TravelStats(
      totalVisits: visits.length,
      countryCount: countryCounts.length,
      cityCount: cityCounts.length,
      firstVisit: sorted.first,
      latestVisit: sorted.last,
      busiestMonth: busiestMonth,
      busiestMonthCount: busiestCount < 0 ? 0 : busiestCount,
      longestMonthlyStreak: longestStreak,
      monthCounts: monthCounts,
      topCountries: rank(countryCounts, city: false),
      topCities: rank(cityCounts, city: true),
    );
  }
}

class _RankedPlace {
  const _RankedPlace({
    required this.label,
    required this.count,
    this.suffix,
  });

  final String label;
  final int count;
  final String? suffix;
}

class _StatsHero extends StatelessWidget {
  const _StatsHero({required this.stats});

  final _TravelStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer,
            scheme.tertiaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.text('yourTravelNumbers'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(context.l10n.text('yourTravelNumbersSubtitle')),
          const SizedBox(height: 20),
          Row(
            children: [
              _HeroMetric(
                value: stats.totalVisits,
                label: context.l10n.text('travelDays'),
              ),
              _HeroMetric(
                value: stats.countryCount,
                label: context.l10n.text('countries'),
              ),
              _HeroMetric(
                value: stats.cityCount,
                label: context.l10n.text('cities'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
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

class _RecordGrid extends StatelessWidget {
  const _RecordGrid({required this.stats});

  final _TravelStats stats;

  String _monthName(BuildContext context, int month) {
    const keys = [
      'monthJanuary',
      'monthFebruary',
      'monthMarch',
      'monthApril',
      'monthMay',
      'monthJune',
      'monthJuly',
      'monthAugust',
      'monthSeptember',
      'monthOctober',
      'monthNovember',
      'monthDecember',
    ];
    return context.l10n.text(keys[month - 1]);
  }

  String _date(TravelVisit? visit) {
    if (visit == null) return '—';
    final value = visit.visitDay;
    return '${value.year}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _RecordItem(
        icon: Icons.emoji_events_outlined,
        label: context.l10n.text('busiestMonth'),
        value: _monthName(context, stats.busiestMonth),
        detail:
            '${stats.busiestMonthCount} ${context.l10n.text('recordedVisits')}',
      ),
      _RecordItem(
        icon: Icons.local_fire_department_outlined,
        label: context.l10n.text('longestTravelStreak'),
        value: '${stats.longestMonthlyStreak}',
        detail: context.l10n.text('activeMonths'),
      ),
      _RecordItem(
        icon: Icons.flag_outlined,
        label: context.l10n.text('firstRecordedTrip'),
        value: _date(stats.firstVisit),
        detail: stats.firstVisit?.locationLabel ?? '—',
      ),
      _RecordItem(
        icon: Icons.update_rounded,
        label: context.l10n.text('latestRecordedTrip'),
        value: _date(stats.latestVisit),
        detail: stats.latestVisit?.locationLabel ?? '—',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) => _RecordCard(item: items[index]),
    );
  }
}

class _RecordItem {
  const _RecordItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.item});

  final _RecordItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon),
          const Spacer(),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            item.detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MonthDistribution extends StatelessWidget {
  const _MonthDistribution({required this.stats});

  final _TravelStats stats;

  String _shortMonth(BuildContext context, int month) {
    const keys = [
      'monthShortJan',
      'monthShortFeb',
      'monthShortMar',
      'monthShortApr',
      'monthShortMay',
      'monthShortJun',
      'monthShortJul',
      'monthShortAug',
      'monthShortSep',
      'monthShortOct',
      'monthShortNov',
      'monthShortDec',
    ];
    return context.l10n.text(keys[month - 1]);
  }

  @override
  Widget build(BuildContext context) {
    var maxCount = 1;
    for (final count in stats.monthCounts.values) {
      if (count > maxCount) maxCount = count;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(12, (index) {
          final month = index + 1;
          final count = stats.monthCounts[month] ?? 0;
          final fraction = count / maxCount;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    count == 0 ? '' : '$count',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 90,
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: fraction == 0 ? 0.04 : fraction,
                      widthFactor: 0.72,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: count == 0
                              ? Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                              : Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _shortMonth(context, month),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TopList extends StatelessWidget {
  const _TopList({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<_RankedPlace> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const Divider(height: 1),
          ...List.generate(items.length, (index) {
            final item = items[index];

            return ListTile(
              leading: CircleAvatar(
                radius: 16,
                child: Text('${index + 1}'),
              ),
              title: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: item.suffix == null ? null : Text(item.suffix!),
              trailing: Text(
                '${item.count}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StateView extends StatelessWidget {
  const _StateView({
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
