import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/entities/travel_visit.dart';
import '../providers/travel_history_provider.dart';

class TravelCalendarPage extends StatefulWidget {
  const TravelCalendarPage({super.key});

  @override
  State<TravelCalendarPage> createState() => _TravelCalendarPageState();
}

class _TravelCalendarPageState extends State<TravelCalendarPage> {
  bool _didLoad = false;
  int? _selectedYear;
  int? _selectedMonth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didLoad) return;
    _didLoad = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<TravelHistoryProvider>().refresh();
      if (!mounted) return;

      final visits = context.read<TravelHistoryProvider>().visits;
      if (visits.isEmpty) return;

      final latest = List<TravelVisit>.from(visits)
        ..sort((a, b) => b.visitDay.compareTo(a.visitDay));

      setState(() {
        _selectedYear = latest.first.visitDay.year;
        _selectedMonth = latest.first.visitDay.month;
      });
    });
  }

  List<int> _years(List<TravelVisit> visits) {
    final values = visits.map((visit) => visit.visitDay.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return values;
  }

  List<TravelVisit> _forMonth(
    List<TravelVisit> visits,
    int year,
    int month,
  ) {
    return visits
        .where(
          (visit) =>
              visit.visitDay.year == year &&
              visit.visitDay.month == month,
        )
        .toList(growable: false);
  }

  Map<int, List<TravelVisit>> _groupByDay(List<TravelVisit> visits) {
    final result = <int, List<TravelVisit>>{};

    for (final visit in visits) {
      result.putIfAbsent(visit.visitDay.day, () => <TravelVisit>[]).add(visit);
    }

    return result;
  }

  String _monthName(BuildContext context, int month) {
    final keys = <String>[
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

  int _daysInMonth(int year, int month) {
    final firstNextMonth = month == 12
        ? DateTime(year + 1, 1)
        : DateTime(year, month + 1);

    return firstNextMonth.subtract(const Duration(days: 1)).day;
  }

  Future<void> _openDay(
    BuildContext context,
    int day,
    List<TravelVisit> visits,
  ) async {
    if (visits.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.text('travelCalendarDayMemories'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 12),
              ...visits.map(
                (visit) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        _flag(visit.countryCode),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    title: Text(
                      visit.locationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${visit.visitDay.year}-'
                      '${visit.visitDay.month.toString().padLeft(2, '0')}-'
                      '${day.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.push(AppRoutes.travelMemoryFor(visit.id));
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    await context.read<TravelHistoryProvider>().refresh();
  }

  String _flag(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.length != 2) return '🌍';

    return String.fromCharCodes(
      normalized.codeUnits.map((unit) => unit + 127397),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<TravelHistoryProvider>();
    final visits = history.visits;
    final years = _years(visits);

    final activeYear = _selectedYear ??
        (years.isEmpty ? DateTime.now().year : years.first);

    final activeMonth = _selectedMonth ?? DateTime.now().month;

    final monthVisits = _forMonth(
      visits,
      activeYear,
      activeMonth,
    );

    final byDay = _groupByDay(monthVisits);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('travelCalendar')),
      ),
      body: history.isLoading && visits.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : history.errorMessage != null && visits.isEmpty
              ? _CalendarState(
                  icon: Icons.cloud_off_rounded,
                  title: context.l10n.text('travelCalendarLoadFailed'),
                  message:
                      context.l10n.text('travelCalendarLoadFailedMessage'),
                  action: FilledButton.tonalIcon(
                    onPressed: history.refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.l10n.text('retry')),
                  ),
                )
              : visits.isEmpty
                  ? _CalendarState(
                      icon: Icons.calendar_month_outlined,
                      title: context.l10n.text('travelCalendarEmptyTitle'),
                      message: context.l10n.text('travelCalendarEmptyMessage'),
                    )
                  : RefreshIndicator(
                      onRefresh: history.refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        children: [
                          _CalendarHero(
                            year: activeYear,
                            monthName: _monthName(context, activeMonth),
                            countryCount: monthVisits
                                .map((visit) => visit.countryCode.toUpperCase())
                                .toSet()
                                .length,
                            cityCount: monthVisits
                                .map(
                                  (visit) =>
                                      '${visit.countryCode.toUpperCase()}|'
                                      '${visit.cityName.toLowerCase()}',
                                )
                                .toSet()
                                .length,
                            travelDayCount: byDay.length,
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
                                  selected: year == activeYear,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedYear = year;

                                      final availableMonths = visits
                                          .where(
                                            (visit) =>
                                                visit.visitDay.year == year,
                                          )
                                          .map((visit) => visit.visitDay.month)
                                          .toSet();

                                      if (!availableMonths
                                          .contains(activeMonth)) {
                                        final sorted =
                                            availableMonths.toList()
                                              ..sort(
                                                (a, b) => b.compareTo(a),
                                              );

                                        if (sorted.isNotEmpty) {
                                          _selectedMonth = sorted.first;
                                        }
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 42,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: 12,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final month = index + 1;

                                return ChoiceChip(
                                  label: Text(_monthName(context, month)),
                                  selected: month == activeMonth,
                                  onSelected: (_) {
                                    setState(() => _selectedMonth = month);
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          _MonthCalendar(
                            year: activeYear,
                            month: activeMonth,
                            dayVisits: byDay,
                            onTapDay: (day, dayVisits) =>
                                _openDay(context, day, dayVisits),
                          ),
                          const SizedBox(height: 18),
                          _Legend(),
                        ],
                      ),
                    ),
    );
  }
}

class _CalendarHero extends StatelessWidget {
  const _CalendarHero({
    required this.year,
    required this.monthName,
    required this.countryCount,
    required this.cityCount,
    required this.travelDayCount,
  });

  final int year;
  final String monthName;
  final int countryCount;
  final int cityCount;
  final int travelDayCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.tertiaryContainer,
            scheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$monthName $year',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(context.l10n.text('travelCalendarSubtitle')),
          const SizedBox(height: 18),
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

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.year,
    required this.month,
    required this.dayVisits,
    required this.onTapDay,
  });

  final int year;
  final int month;
  final Map<int, List<TravelVisit>> dayVisits;
  final void Function(int day, List<TravelVisit> visits) onTapDay;

  int _daysInMonth() {
    final nextMonth = month == 12
        ? DateTime(year + 1, 1)
        : DateTime(year, month + 1);

    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(year, month, 1).weekday;
    final emptyLeading = firstWeekday - DateTime.monday;
    final days = _daysInMonth();
    final totalCells = emptyLeading + days;

    return Column(
      children: [
        Row(
          children: const [
            _Weekday(label: 'M'),
            _Weekday(label: 'T'),
            _Weekday(label: 'W'),
            _Weekday(label: 'T'),
            _Weekday(label: 'F'),
            _Weekday(label: 'S'),
            _Weekday(label: 'S'),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            if (index < emptyLeading) {
              return const SizedBox.shrink();
            }

            final day = index - emptyLeading + 1;
            final visits = dayVisits[day] ?? const <TravelVisit>[];

            return _DayCell(
              day: day,
              visits: visits,
              onTap: visits.isEmpty
                  ? null
                  : () => onTapDay(day, visits),
            );
          },
        ),
      ],
    );
  }
}

class _Weekday extends StatelessWidget {
  const _Weekday({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.visits,
    required this.onTap,
  });

  final int day;
  final List<TravelVisit> visits;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = visits.isNotEmpty;

    return Material(
      color: active
          ? scheme.primaryContainer
          : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontWeight: active ? FontWeight.w900 : FontWeight.w500,
                ),
              ),
            ),
            if (active)
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 17,
                    minHeight: 17,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${visits.length}',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.l10n.text('travelCalendarLegend'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _CalendarState extends StatelessWidget {
  const _CalendarState({
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
