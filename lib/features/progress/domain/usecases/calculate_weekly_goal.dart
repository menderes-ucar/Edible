class WeeklyGoalSnapshot {
  const WeeklyGoalSnapshot({
    required this.thisWeekCount,
    required this.goal,
    required this.currentStreakWeeks,
    required this.bestStreakWeeks,
  });

  final int thisWeekCount;
  final int goal;

  /// Consecutive weeks (ending this week, or last week while this week is still
  /// open) in which the goal was reached.
  final int currentStreakWeeks;
  final int bestStreakWeeks;

  bool get goalReached => thisWeekCount >= goal;
  double get progress => goal <= 0 ? 0 : (thisWeekCount / goal).clamp(0.0, 1.0);
}

/// Weekly discovery goal and week streak. Weeks run Monday to Sunday in local
/// time. A week counts when at least [goal] distinct discoveries were first
/// marked visited/tried in it.
class CalculateWeeklyGoal {
  const CalculateWeeklyGoal();

  static const defaultGoal = 3;

  WeeklyGoalSnapshot call({
    required Iterable<DateTime> discoveryTimes,
    required DateTime now,
    int goal = defaultGoal,
  }) {
    final safeGoal = goal < 1 ? 1 : goal;
    final counts = <DateTime, int>{};

    for (final time in discoveryTimes) {
      final local = time.toLocal();
      if (local.isAfter(now)) continue; // ignore clock-skewed future events
      final week = _weekStart(local);
      counts[week] = (counts[week] ?? 0) + 1;
    }

    final thisWeek = _weekStart(now);
    final thisCount = counts[thisWeek] ?? 0;

    // Current streak: walk back from this week (if already reached) or from
    // last week (so a streak is not lost before the week is over).
    var cursor = thisCount >= safeGoal ? thisWeek : _addWeeks(thisWeek, -1);
    var current = 0;
    while ((counts[cursor] ?? 0) >= safeGoal) {
      current += 1;
      cursor = _addWeeks(cursor, -1);
    }

    // Best streak over all recorded weeks.
    final qualifying = counts.entries
        .where((entry) => entry.value >= safeGoal)
        .map((entry) => entry.key)
        .toList()
      ..sort();
    var best = 0;
    var run = 0;
    DateTime? previous;
    for (final week in qualifying) {
      run = (previous != null && _addWeeks(previous, 1) == week) ? run + 1 : 1;
      if (run > best) best = run;
      previous = week;
    }

    return WeeklyGoalSnapshot(
      thisWeekCount: thisCount,
      goal: safeGoal,
      currentStreakWeeks: current,
      bestStreakWeeks: best > current ? best : current,
    );
  }

  // Built from calendar fields so daylight-saving changes cannot shift a week.
  DateTime _weekStart(DateTime date) =>
      DateTime(date.year, date.month, date.day - (date.weekday - 1));

  DateTime _addWeeks(DateTime weekStart, int weeks) =>
      DateTime(weekStart.year, weekStart.month, weekStart.day + weeks * 7);
}
