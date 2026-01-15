// lib/screens/workout_plan_screen.dart

import 'package:flutter/material.dart';

import '../models.dart';
import 'planner_screen.dart';
import 'day_plan_editor_screen.dart';

class WorkoutPlanScreen extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final List<Exercise> exercises;

  final void Function(WorkoutSession) onAddSession;
  final void Function(WorkoutSession) onDeleteSession;

  // ✅ Needed to show nutrition progress for each day
  final List<MealEntry> meals;

  final List<CookbookMeal> cookbookMeals;
  final WeeklyNutritionGoals weeklyGoals;
  final void Function(WeeklyNutritionGoals) onUpdateWeeklyGoals;

  final WeeklyPlanExtras weeklyPlanExtras;
  final void Function(WeeklyPlanExtras) onUpdateWeeklyPlanExtras;

  const WorkoutPlanScreen({
    super.key,
    required this.sessions,
    required this.exercises,
    required this.onAddSession,
    required this.onDeleteSession,
    required this.meals,
    required this.cookbookMeals,
    required this.weeklyGoals,
    required this.onUpdateWeeklyGoals,
    required this.weeklyPlanExtras,
    required this.onUpdateWeeklyPlanExtras,
  });

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  DateTime _startOfThisWeek(DateTime now) {
    // Monday start
    final d = _dateOnly(now);
    final delta = d.weekday - DateTime.monday;
    return d.subtract(Duration(days: delta));
  }

  List<DateTime> _thisWeekDates() {
    final start = _startOfThisWeek(DateTime.now());
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  List<WorkoutSession> _sessionsForDate(DateTime date) {
    final d = _dateOnly(date);
    final list = sessions
        .where((s) => _dateOnly(s.date) == d)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  // --- Nutrition totals for a day (from MealEntry logs) ---
  Map<String, num> _nutritionTotalsForDate(DateTime date) {
    final d = _dateOnly(date);
    final dayMeals = meals.where((m) => _dateOnly(m.dateTime) == d);

    num kcal = 0, p = 0, c = 0, f = 0, fiber = 0;
    for (final m in dayMeals) {
      kcal += m.calories ?? 0;
      p += m.protein ?? 0;
      c += m.carbs ?? 0;
      f += m.fat ?? 0;
      fiber += m.fiber ?? 0;
    }
    return {
      'kcal': kcal,
      'protein': p,
      'carbs': c,
      'fat': f,
      'fiber': fiber,
    };
  }

  double _progress(num actual, num target) {
    if (target <= 0) return 0;
    final v = (actual / target);
    if (v.isNaN || v.isInfinite) return 0;
    return v.clamp(0.0, 1.0).toDouble();
  }

  // --- Add Activity sheet ---
  Future<void> _openAddActivitySheet(BuildContext context, DateTime date) async {
    final weekday = date.weekday;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('${_weekdayLabel(weekday)} • ${_fmt(date)}'),
                subtitle: const Text('Add something to this specific day'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: const Text('Add workout'),
                subtitle: const Text('Template or custom exercise list'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _openAddWorkoutFlow(context, date);
                },
              ),
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('Edit nutrition plan'),
                subtitle: const Text('Macros, micros, cookbook meals, run, suggestions'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _openNutritionEditor(context, weekday);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Nutrition editor (your DayPlanEditorScreen) ---
  Future<void> _openNutritionEditor(BuildContext context, int weekday) async {
    final goal = weeklyGoals.byWeekday[weekday];
    final dayExtras = weeklyPlanExtras.forWeekday(weekday);

    final workoutSummary = _buildWorkoutSummaryForWeekday(weekday);

    final result = await Navigator.of(context).push<DayPlanEditResult>(
      MaterialPageRoute(
        builder: (_) => DayPlanEditorScreen(
          weekday: weekday,
          weeklyGoals: weeklyGoals,
          weeklyPlanExtras: weeklyPlanExtras,
          cookbookMeals: cookbookMeals,
          workoutSummary: workoutSummary,
          onEditWorkout: () async {
            // Optional: you can decide later what "edit workout" means here.
            // For now, we simply open the Planner weekly editor (not required).
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlannerScreen(
                  existingSessions: sessions,
                  allExercises: exercises,
                  onAddSession: onAddSession,
                  onDeleteSession: onDeleteSession,
                  cookbookMeals: cookbookMeals,
                  weeklyGoals: weeklyGoals,
                  onUpdateWeeklyGoals: onUpdateWeeklyGoals,
                  weeklyPlanExtras: weeklyPlanExtras,
                  onUpdateWeeklyPlanExtras: onUpdateWeeklyPlanExtras,
                ),
              ),
            );
          },
        ),
      ),
    );

    if (result != null) {
      onUpdateWeeklyGoals(result.weeklyGoals);
      onUpdateWeeklyPlanExtras(result.weeklyPlanExtras);
    }
  }

  String _buildWorkoutSummaryForWeekday(int weekday) {
    // Weekday summary: show weekly-plan sessions (next 7 days) for that weekday
    final start = _startOfThisWeek(DateTime.now());
    final end = start.add(const Duration(days: 6));

    final list = sessions.where((s) {
      final d = _dateOnly(s.date);
      return s.status == WorkoutStatus.planned &&
          s.source == 'weekly_plan' &&
          s.date.weekday == weekday &&
          !d.isBefore(start) &&
          !d.isAfter(end);
    }).toList();

    if (list.isEmpty) return 'No weekly-plan workout set for this weekday.';
    final s = list.first;
    return '${s.name} • ${s.exercises.length} exercises';
  }

  // --- Workout add flow (template OR custom) ---
  Future<void> _openAddWorkoutFlow(BuildContext context, DateTime date) async {
    final templates = sessions
        .where((s) => s.status == WorkoutStatus.completed)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    // Select mode
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Wrap(
              runSpacing: 12,
              children: [
                Text(
                  'Add workout • ${_fmt(date)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Use a template (from completed workouts)'),
                  subtitle: Text(templates.isEmpty
                      ? 'No completed sessions available yet.'
                      : '${templates.length} templates available'),
                  onTap: templates.isEmpty
                      ? null
                      : () async {
                          Navigator.of(ctx).pop();
                          await _pickTemplateAndAdd(context, date, templates);
                        },
                ),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Custom (pick exercises)'),
                  subtitle: const Text('Build a workout for this day'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _pickCustomExercisesAndAdd(context, date);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickTemplateAndAdd(
    BuildContext context,
    DateTime date,
    List<WorkoutSession> templates,
  ) async {
    WorkoutSession? chosen;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text('Choose template'),
                subtitle: Text('From completed workouts'),
              ),
              const Divider(height: 1),
              ...templates.map((t) {
                return ListTile(
                  title: Text(t.name),
                  subtitle: Text('${t.exercises.length} exercises'),
                  onTap: () {
                    chosen = t;
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );

    if (chosen == null) return;

    final copiedExercises = chosen!.exercises.map((we) {
      return WorkoutExercise(
        id: '${date.millisecondsSinceEpoch}_${we.id}',
        exercise: we.exercise,
        sets: <ExerciseSet>[],
      );
    }).toList();

    onAddSession(
      WorkoutSession(
        id: '${date.millisecondsSinceEpoch}_daily_template_${chosen!.id}',
        name: chosen!.name,
        date: date,
        exercises: copiedExercises,
        status: WorkoutStatus.planned,
        source: 'daily_plan',
      ),
    );
  }

  Future<void> _pickCustomExercisesAndAdd(BuildContext context, DateTime date) async {
    final all = exercises;
    final nameCtrl = TextEditingController(text: 'Workout');
    final selected = <String>{};

    final result = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (_, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Custom workout • ${_fmt(date)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Workout name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: all.length,
                          itemBuilder: (context, i) {
                            final ex = all[i];
                            final isOn = selected.contains(ex.id);
                            return CheckboxListTile(
                              value: isOn,
                              onChanged: (v) {
                                setModalState(() {
                                  if (v == true) {
                                    selected.add(ex.id);
                                  } else {
                                    selected.remove(ex.id);
                                  }
                                });
                              },
                              title: Text(ex.name),
                              subtitle: Text(muscleGroupLabel(ex.group)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () {
                              if (selected.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Pick at least one exercise.')),
                                );
                                return;
                              }
                              Navigator.of(ctx).pop(true);
                            },
                            child: const Text('Add workout'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (result != true) return;

    final chosenExercises = all.where((e) => selected.contains(e.id)).toList();
    final copiedExercises = chosenExercises.map((ex) {
      return WorkoutExercise(
        id: '${date.millisecondsSinceEpoch}_${ex.id}',
        exercise: ex,
        sets: <ExerciseSet>[],
      );
    }).toList();

    onAddSession(
      WorkoutSession(
        id: '${date.millisecondsSinceEpoch}_daily_custom',
        name: nameCtrl.text.trim().isEmpty ? 'Workout' : nameCtrl.text.trim(),
        date: date,
        exercises: copiedExercises,
        status: WorkoutStatus.planned,
        source: 'daily_plan',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dates = _thisWeekDates();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Workout Plan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header row: "This Week" + Edit Weekly Plan
          Row(
            children: [
              Expanded(
                child: Text(
                  'This Week',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlannerScreen(
                        existingSessions: sessions,
                        allExercises: exercises,
                        onAddSession: onAddSession,
                        onDeleteSession: onDeleteSession,
                        cookbookMeals: cookbookMeals,
                        weeklyGoals: weeklyGoals,
                        onUpdateWeeklyGoals: onUpdateWeeklyGoals,
                        weeklyPlanExtras: weeklyPlanExtras,
                        onUpdateWeeklyPlanExtras: onUpdateWeeklyPlanExtras,
                      ),
                    ),
                  );
                },
                child: const Text('Edit Weekly Plan'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...dates.map((date) => _dayCard(context, date)).toList(),
        ],
      ),
    );
  }

  Widget _dayCard(BuildContext context, DateTime date) {
    final theme = Theme.of(context);
    final weekday = date.weekday;

    final daySessions = _sessionsForDate(date);
    final totals = _nutritionTotalsForDate(date);

    final goal = weeklyGoals.byWeekday[weekday];
    final dayExtras = weeklyPlanExtras.forWeekday(weekday);

    final plannedCookbookMealsCount = dayExtras.mealsByType.values.fold<int>(
      0,
      (sum, ids) => sum + ids.length,
    );
    final microCount = dayExtras.microGoals.length;
    final run = dayExtras.runPlan;

    // Weights summary (treat all WorkoutSessions as "weights" for now)
    final completedWeights = daySessions.where((s) => s.status == WorkoutStatus.completed).length;
    final plannedWeights = daySessions.where((s) => s.status == WorkoutStatus.planned).length;

    String weightsTagText() {
      if (daySessions.isEmpty) return 'Weights: none';
      if (completedWeights > 0) return 'Weights: $completedWeights done';
      return 'Weights: $plannedWeights planned';
    }

    String cardioTagText() {
      if (run == null) return 'Cardio: none';
      return 'Cardio: ${runTargetTypeLabel(run.targetType)}';
    }

    String mealsTagText() {
      if (plannedCookbookMealsCount == 0) return 'Meals: none planned';
      return 'Meals: $plannedCookbookMealsCount planned';
    }

    String microsTagText() {
      if (microCount == 0) return 'Micros: none';
      return 'Micros: $microCount';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  const SizedBox(width: 36), // keeps date centered
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _weekdayLabel(weekday),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _fmt(date),
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add activity',
                    icon: const Icon(Icons.add),
                    onPressed: () => _openAddActivitySheet(context, date),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TAG ROW (now includes weights + cardio on equal ground)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _miniTag(context, icon: Icons.fitness_center, text: weightsTagText()),
                      _miniTag(context, icon: Icons.directions_run, text: cardioTagText()),
                      _miniTag(context, icon: Icons.menu_book, text: mealsTagText()),
                      _miniTag(context, icon: Icons.health_and_safety, text: microsTagText()),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 1) WEIGHTS block
                  _blockCard(
                    context,
                    icon: Icons.fitness_center,
                    title: 'Weights',
                    child: daySessions.isEmpty
                        ? Text('No weights workout planned/logged.', style: theme.textTheme.bodySmall)
                        : Column(
                            children: daySessions.map((s) {
                              final tag =
                                  s.status == WorkoutStatus.completed ? 'Completed' : 'Planned';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      s.status == WorkoutStatus.completed
                                          ? Icons.check_circle
                                          : Icons.schedule,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${s.name} • ${s.exercises.length} exercises',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(tag, style: theme.textTheme.labelSmall),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),

                  // 2) CARDIO block (RunPlan)
                  _blockCard(
                    context,
                    icon: Icons.directions_run,
                    title: 'Cardio',
                    child: run == null
                        ? Text('No cardio planned.', style: theme.textTheme.bodySmall)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                run.title?.trim().isNotEmpty == true
                                    ? run.title!.trim()
                                    : 'Run',
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Target: ${runTargetTypeLabel(run.targetType)}'
                                '${run.minutes != null ? ' • ${run.minutes} min' : ''}'
                                '${run.distanceKm != null ? ' • ${run.distanceKm!.toStringAsFixed(1)} km' : ''}'
                                '${(run.paceMinPerKm ?? '').isNotEmpty ? ' • ${run.paceMinPerKm} min/km' : ''}'
                                '${run.targetBpm != null ? ' • ${run.targetBpm} bpm' : ''}',
                                style: theme.textTheme.bodySmall,
                              ),
                              if ((run.notes ?? '').trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(run.notes!.trim(), style: theme.textTheme.bodySmall),
                              ],
                            ],
                          ),
                  ),

                  // 3) NUTRITION block
                  _blockCard(
                    context,
                    icon: Icons.restaurant,
                    title: 'Nutrition',
                    child: goal == null
                        ? Text(
                            'No macro goal set for this day.',
                            style: theme.textTheme.bodySmall,
                          )
                        : Column(
                            children: [
                              _progressRow(
                                context,
                                label: 'Calories',
                                actual: totals['kcal'] ?? 0,
                                target: goal.calories ?? 0,
                                suffix: 'kcal',
                              ),
                              const SizedBox(height: 8),
                              _progressRow(
                                context,
                                label: 'Protein',
                                actual: totals['protein'] ?? 0,
                                target: goal.protein ?? 0,
                                suffix: 'g',
                              ),
                              const SizedBox(height: 8),
                              _progressRow(
                                context,
                                label: 'Carbs',
                                actual: totals['carbs'] ?? 0,
                                target: goal.carbs ?? 0,
                                suffix: 'g',
                              ),
                              const SizedBox(height: 8),
                              _progressRow(
                                context,
                                label: 'Fat',
                                actual: totals['fat'] ?? 0,
                                target: goal.fat ?? 0,
                                suffix: 'g',
                              ),
                              const SizedBox(height: 8),
                              _progressRow(
                                context,
                                label: 'Fiber',
                                actual: totals['fiber'] ?? 0,
                                target: goal.fiber ?? 0,
                                suffix: 'g',
                              ),
                            ],
                          ),
                  ),

                  // Edit day plan (still available, just no "Set" button anymore)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _openNutritionEditor(context, weekday),
                      icon: const Icon(Icons.tune),
                      label: const Text('Edit day plan'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _progressRow(
    BuildContext context, {
    required String label,
    required num actual,
    required num target,
    required String suffix,
  }) {
    final theme = Theme.of(context);
    final p = _progress(actual, target);

    String fmt(num v) => v.toDouble().toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
            Text(
              '${fmt(actual)} / ${fmt(target)} $suffix',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: p),
      ],
    );
  }

  Widget _chip(BuildContext context, {required IconData icon, required String text}) {
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

  String _fmtNum(num v) => v.toDouble().toStringAsFixed(0);

  Widget _blockCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _miniTag(BuildContext context, {required IconData icon, required String text}) {
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

}
