import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models.dart';
import 'today_screen.dart';
import 'history_screen.dart';
import 'exercises_screen.dart';
import 'stats_screen.dart';
import 'planner_screen.dart';
import 'calendar_screen.dart';
import 'workout_plan_screen.dart';

class FitnessHomeScreen extends StatelessWidget {
  final List<Exercise> exercises;
  final List<WorkoutSession> sessions;

  final void Function(WorkoutSession) onAddSession;
  final void Function(Exercise) onAddExercise;
  final VoidCallback onSessionsChanged;
  final void Function(WorkoutSession) onDeleteSession;
  final void Function(Exercise) onUpdateExercise;
  final Future<void> Function() onClearAll;

  // For nutrition-aware stats (kept for StatsScreen)
  final List<MealEntry> meals;
  final NutritionGoal? nutritionGoal;

  const FitnessHomeScreen({
    super.key,
    required this.exercises,
    required this.sessions,
    required this.onAddSession,
    required this.onAddExercise,
    required this.onSessionsChanged,
    required this.onDeleteSession,
    required this.onUpdateExercise,
    required this.onClearAll,
    required this.meals,
    required this.nutritionGoal,
  });

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  int _countSets(WorkoutSession s) {
    return s.exercises.fold<int>(
      0,
      (sum, we) => sum + we.sets.length,
    );
  }

  /// Simple “improving” heuristic:
  /// For each exercise, compare latest max weight vs previous max weight.
  List<String> _improvingExerciseNames() {
    // Map: exerciseId -> list of (date, maxWeight)
    final map = <String, List<MapEntry<DateTime, double>>>{};

    for (final s in sessions) {
      if (s.status != WorkoutStatus.completed) continue;
      for (final we in s.exercises) {
        double maxW = 0;
        for (final set in we.sets) {
          final w = set.weight ?? 0;
          if (w > maxW) maxW = w;
        }
        map.putIfAbsent(we.exercise.id, () => []);
        map[we.exercise.id]!.add(MapEntry(s.date, maxW));
      }
    }

    final improving = <MapEntry<String, double>>[]; // (name, delta)

    map.forEach((exId, entries) {
      entries.sort((a, b) => a.key.compareTo(b.key));
      if (entries.length < 2) return;

      final last = entries[entries.length - 1].value;
      final prev = entries[entries.length - 2].value;
      final delta = last - prev;
      if (delta > 0.0001) {
        final ex = exercises.firstWhere(
          (e) => e.id == exId,
          orElse: () => Exercise(
            id: exId,
            name: 'Unknown',
            region: BodyRegion.upper,
            group: MuscleGroup.midChest,
          ),
        );
        improving.add(MapEntry(ex.name, delta));
      }
    });

    improving.sort((a, b) => b.value.compareTo(a.value));
    return improving.take(3).map((e) => e.key).toList();
  }

  // ---------------- DASHBOARD DIAGNOSTICS ----------------

  int _countSetsInSession(WorkoutSession s) =>
      s.exercises.fold<int>(0, (sum, we) => sum + we.sets.length);

  /// Consecutive-day streak based on completed sessions (any day with >=1 completed session counts).
  int _currentStreakDays(List<WorkoutSession> sessions) {
    final completedDays = sessions
        .where((s) => s.status == WorkoutStatus.completed)
        .map((s) => _dateOnly(s.date))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    if (completedDays.isEmpty) return 0;

    int streak = 0;
    DateTime cursor = _dateOnly(DateTime.now());

    // If you haven't trained today, allow streak to continue from yesterday
    if (!completedDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    while (completedDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Returns list of 7 values (oldest -> newest) of sets/day for the last 7 days.
  List<double> _setsLast7Days(List<WorkoutSession> sessions) {
    final today = _dateOnly(DateTime.now());
    final start = today.subtract(const Duration(days: 6));

    final map = <DateTime, int>{};
    for (int i = 0; i < 7; i++) {
      map[start.add(Duration(days: i))] = 0;
    }

    for (final s in sessions) {
      if (s.status != WorkoutStatus.completed) continue;
      final day = _dateOnly(s.date);
      if (day.isBefore(start) || day.isAfter(today)) continue;
      map[day] = (map[day] ?? 0) + _countSetsInSession(s);
    }

    return List.generate(7, (i) {
      final d = start.add(Duration(days: i));
      return (map[d] ?? 0).toDouble();
    });
  }

  /// Count "new PRs" this week:
  /// For each exercise, compare max weight this week vs max weight before this week.
  /// (Does not count first-ever lift as a PR, to avoid inflating early.)
  int _prsThisWeek(List<WorkoutSession> sessions) {
    final today = _dateOnly(DateTime.now());
    final weekStart = today.subtract(const Duration(days: 6));

    final prevMax = <String, double>{};
    final weekMax = <String, double>{};

    for (final s in sessions) {
      if (s.status != WorkoutStatus.completed) continue;
      final day = _dateOnly(s.date);

      for (final we in s.exercises) {
        double maxW = 0;
        for (final set in we.sets) {
          if (set.weight != null && set.weight! > maxW) {
            maxW = set.weight!;
          }
        }
        if (maxW <= 0) continue;

        final id = we.exercise.id;
        if (day.isBefore(weekStart)) {
          prevMax[id] = math.max(prevMax[id] ?? 0, maxW);
        } else if (!day.isAfter(today)) {
          weekMax[id] = math.max(weekMax[id] ?? 0, maxW);
        }
      }
    }

    int prs = 0;
    weekMax.forEach((id, wMax) {
      final p = prevMax[id] ?? 0;
      if (p > 0 && wMax > p) prs++;
    });

    return prs;
  }

  /// Most-used exercises (by total sets across all completed sessions)
  List<Exercise> _topExercisesByUsage({
    required List<WorkoutSession> sessions,
    required List<Exercise> exercises,
    int maxItems = 10,
  }) {
    final counts = <String, int>{};

    for (final s in sessions) {
      if (s.status != WorkoutStatus.completed) continue;
      for (final we in s.exercises) {
        if (we.sets.isEmpty) continue;
        counts[we.exercise.id] = (counts[we.exercise.id] ?? 0) + we.sets.length;
      }
    }

    final sortedIds = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final idToEx = {for (final e in exercises) e.id: e};

    final result = <Exercise>[];
    for (final entry in sortedIds.take(maxItems)) {
      final ex = idToEx[entry.key];
      if (ex != null) result.add(ex);
    }

    if (result.isEmpty) {
      return exercises.take(maxItems).toList();
    }

    return result;
  }

  // ---------------- MINI UI WIDGETS ----------------

  Widget _pill(BuildContext context, {required IconData icon, required String text}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }

  Widget _sparkline(List<double> values, ThemeData theme) {
    final safe = values.isEmpty ? const [0.0] : values;
    final maxY = safe.reduce((a, b) => a > b ? a : b);
    final yTop = (maxY <= 0) ? 1.0 : maxY * 1.2;

    final spots = <FlSpot>[];
    for (int i = 0; i < safe.length; i++) {
      spots.add(FlSpot(i.toDouble(), safe[i]));
    }

    return SizedBox(
      height: 46,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (safe.length - 1).toDouble(),
          minY: 0,
          maxY: yTop,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              color: theme.colorScheme.primary,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekDots({
    required BuildContext context,
    required List<WorkoutSession> sessions,
  }) {
    final theme = Theme.of(context);
    final today = _dateOnly(DateTime.now());
    final start = today.subtract(const Duration(days: 6));

    bool hasCompleted(DateTime d) => sessions.any(
          (s) => s.status == WorkoutStatus.completed && _dateOnly(s.date) == d,
        );

    bool hasPlanned(DateTime d) => sessions.any(
          (s) => s.status == WorkoutStatus.planned && _dateOnly(s.date) == d,
        );

    Color dotColor(DateTime d) {
      if (hasCompleted(d)) return theme.colorScheme.primary;
      if (hasPlanned(d)) return theme.colorScheme.secondary;
      return theme.colorScheme.outlineVariant;
    }

    return Row(
      children: List.generate(7, (i) {
        final d = start.add(Duration(days: i));
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor(d),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = _dateOnly(DateTime.now());

    final completed = sessions.where((s) => s.status == WorkoutStatus.completed).toList();
    final plannedAll = sessions.where((s) => s.status == WorkoutStatus.planned).toList();

    final upcoming = plannedAll
        .where((s) => !_dateOnly(s.date).isBefore(today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final nextThree = upcoming.take(3).toList();

    // Weekly summary (completed workouts last 7 days)
    final weekAgo = today.subtract(const Duration(days: 7));
    final weekWorkouts = completed.where((s) => _dateOnly(s.date).isAfter(weekAgo)).toList();
    final setsThisWeek = weekWorkouts.fold<int>(0, (sum, s) => sum + _countSets(s));

    final improving = _improvingExerciseNames();

    // Dashboard extras
    final streakDays = _currentStreakDays(sessions);
    const weeklyGoalWorkouts = 3; // v1 default
    final goalProgress =
        weeklyGoalWorkouts == 0 ? 0.0 : (weekWorkouts.length / weeklyGoalWorkouts).clamp(0.0, 1.0);

    final setsTrend7 = _setsLast7Days(sessions);
    final prsThisWeek = _prsThisWeek(sessions);
    final topExercises = _topExercisesByUsage(
      sessions: sessions,
      exercises: exercises,
      maxItems: 10,
    );

    final todaysPlanned = plannedAll.where((s) => _dateOnly(s.date) == today).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    Future<void> openToday() async {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TodayScreen(
            exercises: exercises,
            onSaveSession: onAddSession,
            onAddExercise: onAddExercise,
          ),
        ),
      );
    }

    Future<void> openCalendar() async {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CalendarScreen(
            sessions: sessions,
            exercises: exercises,
            onAddSession: onAddSession,
            onDeleteSession: onDeleteSession,
          ),
        ),
      );
    }

    Future<void> openWorkoutPlan() async {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WorkoutPlanScreen(
            sessions: sessions,
            exercises: exercises,
            onAddSession: onAddSession,
            onDeleteSession: onDeleteSession,
          ),
        ),
      );
    }

    Future<void> openHistory() async {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HistoryScreen(
            sessions: sessions,
            exercises: exercises,
            onSessionsChanged: onSessionsChanged,
            onAddExercise: onAddExercise,
            onDeleteSession: onDeleteSession,
            onAddSession: onAddSession,
          ),
        ),
      );
    }

    Future<void> openStats() async {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StatsScreen(
            sessions: sessions,
            meals: meals,
            nutritionGoal: nutritionGoal,
            onClearAll: onClearAll,
          ),
        ),
      );
    }

    Future<void> openExercises() async {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ExercisesScreen(
            exercises: exercises,
            sessions: sessions,
            onAddExercise: onAddExercise,
            onUpdateExercise: onUpdateExercise,
          ),
        ),
      );
    }

    Future<void> openPlanner() async {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlannerScreen(
            existingSessions: sessions,
            allExercises: exercises,
            onAddSession: onAddSession,
            onDeleteSession: onDeleteSession,
          ),
        ),
      );
    }

    Future<void> quickAddExercise() async {
      final created = await Navigator.of(context).push<Exercise>(
        MaterialPageRoute(
          builder: (_) => ExerciseDetailScreen(
            isNew: true,
            initial: Exercise(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: '',
              region: BodyRegion.upper,
              group: MuscleGroup.midChest,
              secondary: const [],
              subGroup: null,
              goalWeight: null,
              goalReps: null,
              manualPr: null,
            ),
          ),
        ),
      );

      if (created != null) onAddExercise(created);
    }

    Widget tile({
      required Widget child,
      VoidCallback? onTap,
      Color? borderColor,
    }) {
      final theme = Theme.of(context);

      return Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: borderColor ?? Colors.transparent,
            width: 1.3,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1) Log workout tile (full width)
          tile(
            borderColor: Colors.cyanAccent,
            onTap: () => openToday(),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.add,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Log workout',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2) History + Today side-by-side (same height)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: tile(
                    borderColor: Colors.greenAccent,
                    onTap: () => openHistory(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'History',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('${completed.length} completed'),
                        Text('${plannedAll.length} scheduled'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: tile(
                    borderColor: Colors.greenAccent,
                    onTap: () => openToday(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(DateTime.now()),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          todaysPlanned.isEmpty
                              ? 'No workout scheduled'
                              : 'Planned: ${todaysPlanned.first.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),


          const SizedBox(height: 12),

          // 3) Goals & streak (full width)
          tile(
            borderColor: Colors.purpleAccent,
            onTap: () => openStats(),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(value: goalProgress),
                      Text(
                        '${weekWorkouts.length}/$weeklyGoalWorkouts',
                        style: theme.textTheme.labelMedium,
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
                        'Goals & streak',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text('Weekly goal progress • $streakDays day streak'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _pill(context, icon: Icons.local_fire_department, text: '$streakDays day streak'),
                          _pill(context, icon: Icons.flag, text: 'Goal: $weeklyGoalWorkouts/wk'),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 4) Stats (full width) with mini preview
          tile(
            borderColor: Colors.orangeAccent,
            onTap: () => openStats(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Stats',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: 10),
                Text('This week: ${weekWorkouts.length} workouts • $setsThisWeek sets'),
                const SizedBox(height: 8),
                Text(
                  improving.isEmpty
                      ? 'No improvements detected yet (log a couple sessions).'
                      : 'Improving: ${improving.join(', ')}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                _sparkline(setsTrend7, theme),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill(context, icon: Icons.fitness_center, text: '${setsTrend7.fold<double>(0, (a, b) => a + b).toInt()} sets (7d)'),
                    _pill(context, icon: Icons.emoji_events, text: '$prsThisWeek PRs (7d)'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          tile(
            onTap: () => openWorkoutPlan(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Your workout plan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Next 7 days overview • Tap to review & edit',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  nextThree.isEmpty
                      ? 'No upcoming workouts scheduled yet.'
                      : 'Next: ${nextThree.first.name} (${_formatDate(nextThree.first.date)})',
                ),
              ],
            ),
          ),

          // 5) Schedule (full width): show next 3 planned workouts + week dots
          tile(
            borderColor: Colors.pinkAccent,
            onTap: () => openCalendar(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Schedule',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: 8),
                _weekDots(context: context, sessions: sessions),
                const SizedBox(height: 10),
                if (nextThree.isEmpty)
                  Text(
                    'No scheduled workouts yet.',
                    style: theme.textTheme.bodySmall,
                  )
                else
                  Column(
                    children: nextThree.map((s) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: Text(
                                _formatDate(s.date),
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                s.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 6) Exercises (full width): clickable tile + top-used horizontal list + add button
          Card(
            clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.redAccent, width: 1.3),
              ),
            child: InkWell(
              onTap: () => openExercises(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Exercises',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Add exercise',
                          onPressed: quickAddExercise,
                          icon: const Icon(Icons.add),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: topExercises.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          if (i == topExercises.length) {
                            return ActionChip(
                              label: const Text('+ Add'),
                              onPressed: quickAddExercise,
                            );
                          }
                          final e = topExercises[i];
                          return ActionChip(
                            label: Text(
                              e.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () => openExercises(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
