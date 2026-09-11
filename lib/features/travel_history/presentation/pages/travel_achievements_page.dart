import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/travel_visit.dart';
import '../providers/travel_history_provider.dart';

class TravelAchievementsPage extends StatefulWidget {
  const TravelAchievementsPage({super.key});

  @override
  State<TravelAchievementsPage> createState() =>
      _TravelAchievementsPageState();
}

class _TravelAchievementsPageState extends State<TravelAchievementsPage> {
  @override
  Widget build(BuildContext context) {
    final history = context.watch<TravelHistoryProvider>();
    final snapshot = _AchievementSnapshot.from(history.visits);
    final achievements = _buildAchievements(context, snapshot);
    final unlocked =
        achievements.where((achievement) => achievement.isUnlocked).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('travelAchievements')),
      ),
      body: history.isLoading && history.visits.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : history.errorMessage != null && history.visits.isEmpty
              ? _StateView(
                  icon: Icons.cloud_off_rounded,
                  title: context.l10n.text('travelAchievementsLoadFailed'),
                  message:
                      context.l10n.text('travelAchievementsLoadFailedMessage'),
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
                      _AchievementsHero(
                        unlocked: unlocked,
                        total: achievements.length,
                        nextAchievement: achievements.cast<_Achievement?>().firstWhere(
                              (item) => item != null && !item.isUnlocked,
                              orElse: () => null,
                            ),
                      ),
                      const SizedBox(height: 22),
                      if (history.visits.isEmpty)
                        _InlineEmpty(
                          title:
                              context.l10n.text('travelAchievementsEmptyTitle'),
                          message: context.l10n
                              .text('travelAchievementsEmptyMessage'),
                        )
                      else
                        ...achievements.map(
                          (achievement) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AchievementCard(
                              achievement: achievement,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  List<_Achievement> _buildAchievements(
    BuildContext context,
    _AchievementSnapshot snapshot,
  ) {
    return [
      _Achievement(
        icon: Icons.flag_outlined,
        title: context.l10n.text('achievementFirstStamp'),
        description:
            context.l10n.text('achievementFirstStampDescription'),
        current: snapshot.countryCount,
        target: 1,
      ),
      _Achievement(
        icon: Icons.public_outlined,
        title: context.l10n.text('achievementThreeCountries'),
        description:
            context.l10n.text('achievementThreeCountriesDescription'),
        current: snapshot.countryCount,
        target: 3,
      ),
      _Achievement(
        icon: Icons.travel_explore_outlined,
        title: context.l10n.text('achievementFiveCountries'),
        description:
            context.l10n.text('achievementFiveCountriesDescription'),
        current: snapshot.countryCount,
        target: 5,
      ),
      _Achievement(
        icon: Icons.language_outlined,
        title: context.l10n.text('achievementTenCountries'),
        description:
            context.l10n.text('achievementTenCountriesDescription'),
        current: snapshot.countryCount,
        target: 10,
      ),
      _Achievement(
        icon: Icons.location_city_outlined,
        title: context.l10n.text('achievementFiveCities'),
        description:
            context.l10n.text('achievementFiveCitiesDescription'),
        current: snapshot.cityCount,
        target: 5,
      ),
      _Achievement(
        icon: Icons.apartment_outlined,
        title: context.l10n.text('achievementTenCities'),
        description:
            context.l10n.text('achievementTenCitiesDescription'),
        current: snapshot.cityCount,
        target: 10,
      ),
      _Achievement(
        icon: Icons.calendar_month_outlined,
        title: context.l10n.text('achievementFiveTravelDays'),
        description:
            context.l10n.text('achievementFiveTravelDaysDescription'),
        current: snapshot.travelDayCount,
        target: 5,
      ),
      _Achievement(
        icon: Icons.auto_awesome_outlined,
        title: context.l10n.text('achievementTwentyTravelDays'),
        description:
            context.l10n.text('achievementTwentyTravelDaysDescription'),
        current: snapshot.travelDayCount,
        target: 20,
      ),
      _Achievement(
        icon: Icons.local_fire_department_outlined,
        title: context.l10n.text('achievementThreeMonthStreak'),
        description:
            context.l10n.text('achievementThreeMonthStreakDescription'),
        current: snapshot.longestMonthlyStreak,
        target: 3,
      ),
      _Achievement(
        icon: Icons.wb_sunny_outlined,
        title: context.l10n.text('achievementSeasonExplorer'),
        description:
            context.l10n.text('achievementSeasonExplorerDescription'),
        current: snapshot.seasonCount,
        target: 4,
      ),
    ];
  }
}

class _AchievementSnapshot {
  const _AchievementSnapshot({
    required this.countryCount,
    required this.cityCount,
    required this.travelDayCount,
    required this.longestMonthlyStreak,
    required this.seasonCount,
  });

  final int countryCount;
  final int cityCount;
  final int travelDayCount;
  final int longestMonthlyStreak;
  final int seasonCount;

  factory _AchievementSnapshot.from(List<TravelVisit> visits) {
    final countries = <String>{};
    final cities = <String>{};
    final days = <String>{};
    final activeMonths = <int>{};
    final seasons = <int>{};

    for (final visit in visits) {
      final country = visit.countryCode.trim().toUpperCase();
      if (country.isNotEmpty) {
        countries.add(country);
      }

      final city = visit.cityName.trim().toLowerCase();
      if (city.isNotEmpty) {
        cities.add('$country|$city');
      }

      final day = visit.visitDay;
      days.add(
        '${day.year}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}',
      );

      activeMonths.add(day.year * 12 + day.month);

      if (day.month == 12 || day.month <= 2) {
        seasons.add(0);
      } else if (day.month <= 5) {
        seasons.add(1);
      } else if (day.month <= 8) {
        seasons.add(2);
      } else {
        seasons.add(3);
      }
    }

    final sortedMonths = activeMonths.toList()..sort();
    var currentStreak = sortedMonths.isEmpty ? 0 : 1;
    var longestStreak = currentStreak;

    for (var i = 1; i < sortedMonths.length; i++) {
      if (sortedMonths[i] == sortedMonths[i - 1] + 1) {
        currentStreak += 1;
      } else {
        currentStreak = 1;
      }

      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
    }

    return _AchievementSnapshot(
      countryCount: countries.length,
      cityCount: cities.length,
      travelDayCount: days.length,
      longestMonthlyStreak: longestStreak,
      seasonCount: seasons.length,
    );
  }
}

class _Achievement {
  const _Achievement({
    required this.icon,
    required this.title,
    required this.description,
    required this.current,
    required this.target,
  });

  final IconData icon;
  final String title;
  final String description;
  final int current;
  final int target;

  bool get isUnlocked => current >= target;

  double get progress {
    if (target <= 0) return 1;
    return (current / target).clamp(0, 1).toDouble();
  }

  int get remaining {
    final value = target - current;
    return value < 0 ? 0 : value;
  }
}

class _AchievementsHero extends StatelessWidget {
  const _AchievementsHero({
    required this.unlocked,
    required this.total,
    required this.nextAchievement,
  });

  final int unlocked;
  final int total;
  final _Achievement? nextAchievement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final completion = total == 0 ? 0.0 : unlocked / total;

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
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_outlined, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.text('travelAchievementCollection'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$unlocked / $total '
                      '${context.l10n.text('achievementsUnlocked')}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: completion,
            ),
          ),
          if (nextAchievement != null) ...[
            const SizedBox(height: 16),
            Text(
              context.l10n.text('nextAchievement'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${nextAchievement!.title} • '
              '${nextAchievement!.remaining} '
              '${context.l10n.text('toGo')}',
            ),
          ],
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
  });

  final _Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unlocked = achievement.isUnlocked;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked
            ? scheme.primaryContainer.withValues(alpha: 0.55)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: unlocked
              ? scheme.primary.withValues(alpha: 0.35)
              : scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: unlocked
                  ? scheme.primary
                  : scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement.icon,
              color: unlocked ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    Icon(
                      unlocked
                          ? Icons.check_circle_rounded
                          : Icons.lock_outline_rounded,
                      color: unlocked ? scheme.primary : scheme.outline,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(achievement.description),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: achievement.progress,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  unlocked
                      ? context.l10n.text('achievementUnlocked')
                      : '${achievement.current} / ${achievement.target}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium_outlined, size: 48),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
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
