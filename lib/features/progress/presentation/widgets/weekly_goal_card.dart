import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/usecases/calculate_weekly_goal.dart';
import '../providers/progress_provider.dart';

/// Weekly discovery goal with a week streak. Hidden until the data loads and
/// stays hidden if it cannot be loaded (it never blocks the passport page).
class WeeklyGoalCard extends StatefulWidget {
  const WeeklyGoalCard({super.key});

  @override
  State<WeeklyGoalCard> createState() => _WeeklyGoalCardState();
}

class _WeeklyGoalCardState extends State<WeeklyGoalCard> {
  WeeklyGoalSnapshot? _snapshot;
  int _loadedSignature = -1;
  int _generation = 0;

  Future<void> _load() async {
    final repository = context.read<ProgressRepository>();
    final generation = ++_generation;
    try {
      final events = await repository.getDiscoveryEvents();
      if (!mounted || generation != _generation) return;
      setState(() {
        _snapshot = const CalculateWeeklyGoal()(
          discoveryTimes: events.map((event) => event.createdAt),
          now: DateTime.now(),
        );
      });
    } catch (_) {
      // Optional card: keep whatever was shown before, or nothing.
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final signature = progress.visitedCount + progress.triedCount;
    if (signature != _loadedSignature) {
      _loadedSignature = signature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }

    final snapshot = _snapshot;
    if (snapshot == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: snapshot.progress,
                      strokeWidth: 6,
                      backgroundColor: scheme.primaryContainer,
                    ),
                  ),
                  Text(
                    '${snapshot.thisWeekCount}/${snapshot.goal}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.text('weeklyGoalTitle'),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n
                        .text('weeklyGoalProgress')
                        .replaceAll('{done}', '${snapshot.thisWeekCount}')
                        .replaceAll('{goal}', '${snapshot.goal}'),
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    snapshot.goalReached
                        ? l10n.text('weeklyGoalReached')
                        : l10n.text('weeklyGoalHint'),
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 18,
                        color: snapshot.currentStreakWeeks > 0
                            ? Colors.deepOrange
                            : scheme.outline,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          snapshot.currentStreakWeeks > 0
                              ? l10n
                                  .text('weeklyStreak')
                                  .replaceAll(
                                    '{weeks}',
                                    '${snapshot.currentStreakWeeks}',
                                  )
                              : l10n.text('weeklyStreakStart'),
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
