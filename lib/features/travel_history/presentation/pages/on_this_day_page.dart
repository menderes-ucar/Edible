import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/entities/travel_visit.dart';
import '../providers/travel_history_provider.dart';

class OnThisDayPage extends StatefulWidget {
  const OnThisDayPage({super.key});

  @override
  State<OnThisDayPage> createState() => _OnThisDayPageState();
}

class _OnThisDayPageState extends State<OnThisDayPage> {
  List<TravelVisit> _anniversaryVisits(
    List<TravelVisit> visits,
    DateTime today,
  ) {
    final result = visits.where((visit) {
      final day = visit.visitDay;
      return day.year < today.year &&
          day.month == today.month &&
          day.day == today.day;
    }).toList();

    result.sort((a, b) => b.visitDay.compareTo(a.visitDay));
    return result;
  }

  List<TravelVisit> _nearbyThrowbacks(
    List<TravelVisit> visits,
    DateTime today,
  ) {
    final anniversaryIds =
        _anniversaryVisits(visits, today).map((visit) => visit.id).toSet();

    final candidates = visits.where((visit) {
      if (anniversaryIds.contains(visit.id)) {
        return false;
      }
      if (visit.visitDay.year >= today.year) {
        return false;
      }

      final thisYearOccurrence = _safeOccurrence(
        today.year,
        visit.visitDay.month,
        visit.visitDay.day,
      );

      final distance = thisYearOccurrence.difference(
        DateTime(today.year, today.month, today.day),
      );

      return distance.inDays.abs() <= 14;
    }).toList();

    candidates.sort((a, b) {
      final aOccurrence = _safeOccurrence(
        today.year,
        a.visitDay.month,
        a.visitDay.day,
      );
      final bOccurrence = _safeOccurrence(
        today.year,
        b.visitDay.month,
        b.visitDay.day,
      );
      final todayDate = DateTime(today.year, today.month, today.day);

      final aDistance = aOccurrence.difference(todayDate).inDays.abs();
      final bDistance = bOccurrence.difference(todayDate).inDays.abs();

      final byDistance = aDistance.compareTo(bDistance);
      if (byDistance != 0) {
        return byDistance;
      }

      return b.visitDay.compareTo(a.visitDay);
    });

    return candidates.take(6).toList(growable: false);
  }

  DateTime _safeOccurrence(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > lastDay ? lastDay : day);
  }

  String _flag(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.length != 2) {
      return '🌍';
    }

    return String.fromCharCodes(
      normalized.codeUnits.map((unit) => unit + 127397),
    );
  }

  String _formattedDate(DateTime value) {
    return '${value.year}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  int _yearsAgo(DateTime visitDay, DateTime today) {
    var years = today.year - visitDay.year;

    final anniversaryPassed =
        today.month > visitDay.month ||
        (today.month == visitDay.month && today.day >= visitDay.day);

    if (!anniversaryPassed) {
      years -= 1;
    }
    return years < 0 ? 0 : years;
  }

  Future<void> _openMemory(TravelVisit visit) async {
    await context.push(AppRoutes.travelMemoryFor(visit.id));

    if (!mounted) {
      return;
    }
    await context.read<TravelHistoryProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<TravelHistoryProvider>();
    final today = DateTime.now();
    final anniversaries = _anniversaryVisits(history.visits, today);
    final nearby = _nearbyThrowbacks(history.visits, today);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('onThisDay')),
      ),
      body: history.isLoading && history.visits.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : history.errorMessage != null && history.visits.isEmpty
              ? _StateView(
                  icon: Icons.cloud_off_rounded,
                  title: context.l10n.text('onThisDayLoadFailed'),
                  message: context.l10n.text('onThisDayLoadFailedMessage'),
                  action: FilledButton.tonalIcon(
                    onPressed: history.refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.l10n.text('retry')),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: history.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      _Hero(
                        day: today.day,
                        month: today.month,
                        memoryCount: anniversaries.length,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        context.l10n.text('todayTravelMemories'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(context.l10n.text('todayTravelMemoriesSubtitle')),
                      const SizedBox(height: 14),
                      if (anniversaries.isEmpty)
                        _InlineEmpty(
                          title: context.l10n.text('noMemoryToday'),
                          message: context.l10n.text('noMemoryTodayMessage'),
                        )
                      else
                        ...anniversaries.map(
                          (visit) => _MemoryCard(
                            flag: _flag(visit.countryCode),
                            location: visit.locationLabel,
                            dateText: _formattedDate(visit.visitDay),
                            yearsAgo: _yearsAgo(visit.visitDay, today),
                            onTap: () => _openMemory(visit),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        context.l10n.text('nearbyThrowbacks'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(context.l10n.text('nearbyThrowbacksSubtitle')),
                      const SizedBox(height: 14),
                      if (nearby.isEmpty)
                        _InlineEmpty(
                          title: context.l10n.text('noNearbyThrowbacks'),
                          message:
                              context.l10n.text('noNearbyThrowbacksMessage'),
                        )
                      else
                        ...nearby.map(
                          (visit) => _MemoryCard(
                            flag: _flag(visit.countryCode),
                            location: visit.locationLabel,
                            dateText: _formattedDate(visit.visitDay),
                            yearsAgo: _yearsAgo(visit.visitDay, today),
                            onTap: () => _openMemory(visit),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.day,
    required this.month,
    required this.memoryCount,
  });

  final int day;
  final int month;
  final int memoryCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.secondaryContainer,
            scheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  '$month',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.text('onThisDayHeroTitle'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 5),
                Text(context.l10n.text('onThisDayHeroSubtitle')),
                const SizedBox(height: 10),
                Text(
                  '$memoryCount ${context.l10n.text('anniversaryMemories')}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({
    required this.flag,
    required this.location,
    required this.dateText,
    required this.yearsAgo,
    required this.onTap,
  });

  final String flag;
  final String location;
  final String dateText;
  final int yearsAgo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Text(flag, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(dateText),
                    if (yearsAgo > 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        '$yearsAgo ${context.l10n.text('yearsAgo')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(message),
              ],
            ),
          ),
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
