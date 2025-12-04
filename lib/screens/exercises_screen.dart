// lib/screens/exercises_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import 'exercise_detail_screen.dart';

/// Small trend state for the exercise list.
enum _MiniTrend { up, down, stable, none }

double _estimate1RM(double weight, int reps) {
  final r = reps.clamp(1, 30);
  return weight * (1.0 + r / 30.0);
}

class ExercisesScreen extends StatelessWidget {
  final List<Exercise> exercises;
  final List<WorkoutSession> sessions;
  final void Function(Exercise) onAddExercise;
  final void Function(Exercise) onUpdateExercise;

  const ExercisesScreen({
    super.key,
    required this.exercises,
    required this.sessions,
    required this.onAddExercise,
    required this.onUpdateExercise,
  });

  // ------- Progress / trend helpers -------

  /// Returns a time series of max weight (per session) for this exercise.
  List<double> _exerciseMaxWeights(Exercise exercise) {
    final relevant = sessions
        .where((s) =>
            s.exercises.any((we) => we.exercise.id == exercise.id))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final result = <double>[];

    for (final s in relevant) {
      double maxW = 0;
      for (final we in s.exercises) {
        if (we.exercise.id != exercise.id) continue;
        for (final set in we.sets) {
          if (set.weight != null && set.weight! > maxW) {
            maxW = set.weight!;
          }
        }
      }
      if (maxW > 0) {
        result.add(maxW);
      }
    }

    return result;
  }

  _MiniTrend _computeMiniTrend(List<double> values) {
    if (values.length < 3) return _MiniTrend.none;

    final n = values.length;

    // Compare last k vs previous k (k up to 3, and 2k <= n)
    int k = math.min(3, n ~/ 2);
    if (k == 0) k = 1;

    final recent = values.sublist(n - k);
    final previous = values.sublist(n - 2 * k, n - k);

    final avgRecent =
        recent.reduce((a, b) => a + b) / recent.length.toDouble();
    final avgPrev =
        previous.reduce((a, b) => a + b) / previous.length.toDouble();

    if (avgPrev == 0) return _MiniTrend.none;

    final rel = (avgRecent - avgPrev) / avgPrev;

    const upThreshold = 0.05; // +5%
    const downThreshold = -0.05; // -5%

    if (rel > upThreshold) return _MiniTrend.up;
    if (rel < downThreshold) return _MiniTrend.down;
    return _MiniTrend.stable;
  }

  Widget? _buildTrendIcon(
    _MiniTrend trend,
    ThemeData theme,
  ) {
    switch (trend) {
      case _MiniTrend.up:
        return Icon(
          Icons.trending_up,
          color: Colors.green.shade600,
        );
      case _MiniTrend.down:
        return Icon(
          Icons.trending_down,
          color: Colors.red.shade600,
        );
      case _MiniTrend.stable:
        return Icon(
          Icons.trending_flat,
          color: theme.colorScheme.primary,
        );
      case _MiniTrend.none:
        return null;
    }
  }

  /// Progress towards goal based on estimated 1RM, 0..1 or null if no goal.
  double? _goalProgressForExercise(Exercise exercise) {
    final gw = exercise.goalWeight;
    final gr = exercise.goalReps;
    if (gw == null || gr == null || gw <= 0 || gr <= 0) return null;

    final goal1rm = _estimate1RM(gw, gr);
    if (goal1rm <= 0) return null;

    double best1rm = 0;

    for (final s in sessions) {
      for (final we in s.exercises) {
        if (we.exercise.id != exercise.id) continue;
        for (final set in we.sets) {
          if (set.weight == null) continue;
          final est = _estimate1RM(set.weight!, set.reps);
          if (est > best1rm) best1rm = est;
        }
      }
    }

    if (best1rm <= 0) return 0.0;
    return (best1rm / goal1rm).clamp(0.0, 1.0);
  }

  // ------- Add exercise dialog -------

  void _showAddExerciseDialog(BuildContext context) {
    final nameController = TextEditingController();
    final subGroupController = TextEditingController();

    BodyRegion selectedRegion = BodyRegion.upper;
    MuscleGroup selectedGroup = MuscleGroup.midChest;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('New exercise'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<BodyRegion>(
                      value: selectedRegion,
                      decoration: const InputDecoration(
                        labelText: 'Body region',
                      ),
                      items: BodyRegion.values.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(bodyRegionLabel(r)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedRegion = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<MuscleGroup>(
                      value: selectedGroup,
                      decoration: const InputDecoration(
                        labelText: 'Primary muscle',
                      ),
                      items: MuscleGroup.values.map((g) {
                        return DropdownMenuItem(
                          value: g,
                          child: Text(muscleGroupLabel(g)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedGroup = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: subGroupController,
                      decoration: const InputDecoration(
                        labelText: 'Extra info (optional)',
                        hintText: 'e.g. Neutral grip, Cable, etc.',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final sub = subGroupController.text.trim();
                    final exercise = Exercise(
                      id: DateTime.now()
                          .millisecondsSinceEpoch
                          .toString(),
                      name: name,
                      region: selectedRegion,
                      group: selectedGroup,
                      subGroup: sub.isEmpty ? null : sub,
                    );

                    onAddExercise(exercise);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final sortedExercises = List<Exercise>.from(exercises)
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
      ),
      body: ListView.builder(
        itemCount: sortedExercises.length,
        itemBuilder: (context, index) {
          final e = sortedExercises[index];

          final series = _exerciseMaxWeights(e);
          final trend = _computeMiniTrend(series);
          final trendIcon = _buildTrendIcon(trend, theme);

          final goalProgress = _goalProgressForExercise(e);
          Widget trailing;

          if (trendIcon == null && goalProgress == null) {
            trailing = const SizedBox.shrink();
          } else {
            trailing = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (trendIcon != null) trendIcon,
                if (goalProgress != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.flag_outlined,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(goalProgress * 100).round()}%',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }

          return Card(
            child: ListTile(
              title: Text(e.name),
              subtitle: Text(
                '${bodyRegionLabel(e.region)} • ${muscleGroupLabel(e.group)}'
                '${e.subGroup != null ? ' • ${e.subGroup}' : ''}',
              ),
              trailing: trailing,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExerciseDetailScreen(
                      exercise: e,
                      sessions: sessions,
                      onUpdateExercise: onUpdateExercise,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExerciseDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
