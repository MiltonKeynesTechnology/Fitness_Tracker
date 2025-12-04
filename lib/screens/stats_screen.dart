// lib/screens/stats_screen.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';

import '../models.dart';

enum TimeRange {
  day,
  week,
  month,
  year,
  all,
}

class _ExerciseTrendPoint {
  final DateTime date;
  final double maxWeight;
  final double volume; // weight * reps

  _ExerciseTrendPoint(this.date, this.maxWeight, this.volume);
}

class _RecoveryInfo {
  final double score;
  final double? daysSinceLast;
  final RecoveryStatus status;

  _RecoveryInfo({
    required this.score,
    required this.daysSinceLast,
    required this.status,
  });
}

enum RecoveryStatus { fresh, ok, fatigued }

class _LiftTrendResult {
  final Exercise exercise;
  final double deltaAbs;
  final double deltaRel;

  const _LiftTrendResult({
    required this.exercise,
    required this.deltaAbs,
    required this.deltaRel,
  });
}

class StatsScreen extends StatefulWidget {
  final List<WorkoutSession> sessions;
  final Future<void> Function() onClearAll;

  const StatsScreen({
    super.key,
    required this.sessions,
    required this.onClearAll,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  TimeRange _range = TimeRange.week;
  String? _selectedExerciseId;

  List<WorkoutSession> get _filteredSessions {
    if (widget.sessions.isEmpty) return const [];

    if (_range == TimeRange.all) {
      return List.of(widget.sessions);
    }

    final now = DateTime.now();
    late DateTime cutoff;

    switch (_range) {
      case TimeRange.day:
        cutoff = now.subtract(const Duration(days: 1));
        break;
      case TimeRange.week:
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case TimeRange.month:
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case TimeRange.year:
        cutoff = now.subtract(const Duration(days: 365));
        break;
      case TimeRange.all:
        cutoff = DateTime(1970);
        break;
    }

    return widget.sessions.where((s) => s.date.isAfter(cutoff)).toList();
  }

  // ---------- SUMMARY DATA ----------

  Map<MuscleGroup, int> _setsPerMuscleGroup(List<WorkoutSession> sessions) {
    final map = <MuscleGroup, int>{};

    for (final s in sessions) {
      for (final we in s.exercises) {
        if (we.sets.isEmpty) continue; // ignore exercises with no sets
        final group = we.exercise.group;
        final setsCount = we.sets.length;
        if (setsCount == 0) continue;
        map[group] = (map[group] ?? 0) + setsCount;
      }
    }

    return map;
  }

  String _rangeLabel(TimeRange r) {
    switch (r) {
      case TimeRange.day:
        return 'Day';
      case TimeRange.week:
        return 'Week';
      case TimeRange.month:
        return 'Month';
      case TimeRange.year:
        return 'Year';
      case TimeRange.all:
        return 'All time';
    }
  }

  // ---------- EXERCISE LIST & TREND DATA (Stats graphs) ----------

  List<Exercise> _availableExercises(List<WorkoutSession> sessions) {
    final map = <String, Exercise>{};

    for (final s in sessions) {
      for (final we in s.exercises) {
        if (we.sets.isEmpty) continue; // only exercises with actual data
        map[we.exercise.id] = we.exercise;
      }
    }

    final list = map.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  List<_ExerciseTrendPoint> _exerciseTrendData(
    List<WorkoutSession> sessions,
    String exerciseId,
  ) {
    final sorted = List<WorkoutSession>.from(sessions)
      ..sort((a, b) => a.date.compareTo(b.date));

    final points = <_ExerciseTrendPoint>[];

    for (final s in sorted) {
      double maxW = 0;
      double volume = 0;

      for (final we in s.exercises) {
        if (we.exercise.id != exerciseId) continue;

        for (final set in we.sets) {
          if (set.weight != null) {
            if (set.weight! > maxW) maxW = set.weight!;
            volume += set.weight! * set.reps;
          } else {
            // bodyweight: count as reps for volume
            volume += set.reps.toDouble();
          }
        }
      }

      if (maxW > 0 || volume > 0) {
        points.add(_ExerciseTrendPoint(s.date, maxW, volume));
      }
    }

    return points;
  }

  // ---------- CSV EXPORT & CLEAR ALL ----------

  Future<void> _exportCsv(List<WorkoutSession> sessions) async {
    final buffer = StringBuffer();
    buffer.writeln(
        'Date,Workout Name,Exercise,Muscle Group,Reps,Weight,Volume');

    for (final s in sessions) {
      final dateStr =
          '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';

      for (final we in s.exercises) {
        final mg = muscleGroupLabel(we.exercise.group);
        for (final set in we.sets) {
          final weight = set.weight ?? 0;
          final volume = weight * set.reps;
          buffer.writeln(
              '$dateStr,${s.name},${we.exercise.name},$mg,${set.reps},$weight,$volume');
        }
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/training_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported to:\n${file.path}'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _confirmClearAll() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This will delete all workouts and custom exercises.\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (result != true) return;

    await widget.onClearAll();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data cleared.')),
    );
  }

  // ---------- CHARTS & UI HELPERS ----------

  Widget _buildLineChart({
    required List<_ExerciseTrendPoint> data,
    required double Function(_ExerciseTrendPoint p) valueSelector,
    required Color color,
  }) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data for this exercise in this range.'),
      );
    }

    final spots = <FlSpot>[];
    double maxY = 0;

    for (var i = 0; i < data.length; i++) {
      final y = valueSelector(data[i]);
      maxY = y > maxY ? y : maxY;
      spots.add(FlSpot(i.toDouble(), y));
    }

    if (maxY == 0) maxY = 1;

    String labelForIndex(int index) {
      if (index < 0 || index >= data.length) return '';
      final d = data[index].date;
      return '${d.day}/${d.month}';
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxY * 1.1,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: color,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.2),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    labelForIndex(index),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseChips(
    List<Exercise> exercises,
    Exercise? selected,
  ) {
    if (exercises.isEmpty) {
      return const Text('No exercises with sets in this range.');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: exercises.map((e) {
          final isSelected = selected != null && e.id == selected.id;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedExerciseId = e.id;
                });
              },
              child: Column(
                children: [
                  CircleAvatar(
                    radius: isSelected ? 22 : 20,
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                    child: Text(
                      e.name.length > 2
                          ? e.name.substring(0, 2).toUpperCase()
                          : e.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: Text(
                      e.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------- BODY HEATMAP (BLOCKS) ----------

  Color _intensityColorFor(
    Map<MuscleGroup, int> muscleData,
    MuscleGroup group,
  ) {
    final sets = muscleData[group] ?? 0;
    if (sets == 0) {
      return Colors.grey.shade300; // not hit
    }

    final maxSets = muscleData.values.isEmpty
        ? 1
        : muscleData.values.reduce((a, b) => a > b ? a : b);

    final ratio = sets / maxSets;

    if (ratio < 0.34) {
      return Colors.white; // low
    } else if (ratio < 0.67) {
      return Colors.yellow.shade600; // medium
    } else {
      return Colors.red.shade600; // high
    }
  }

  Widget _buildBodyHeatMap(
    BuildContext context,
    Map<MuscleGroup, int> muscleData,
  ) {
    final theme = Theme.of(context);

    Widget muscleBlock(String label, MuscleGroup group) {
      final color = _intensityColorFor(muscleData, group);
      return Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Body heatmap (by sets)',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shoulders
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  muscleBlock('Shoulders', MuscleGroup.shoulders),
                ],
              ),
              const SizedBox(height: 8),
              // Chest / Back
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  muscleBlock('Chest', MuscleGroup.chest),
                  const SizedBox(width: 16),
                  muscleBlock('Back', MuscleGroup.back),
                ],
              ),
              const SizedBox(height: 8),
              // Arms
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  muscleBlock('Arms', MuscleGroup.arms),
                ],
              ),
              const SizedBox(height: 8),
              // Core
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  muscleBlock('Core', MuscleGroup.core),
                ],
              ),
              const SizedBox(height: 8),
              // Glutes / Legs / Calves
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  muscleBlock('Glutes', MuscleGroup.glutes),
                  const SizedBox(width: 16),
                  muscleBlock('Legs', MuscleGroup.legs),
                  const SizedBox(width: 16),
                  muscleBlock('Calves', MuscleGroup.calves),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Intensity: white = low, yellow = medium, red = high (per muscle group in selected time range).',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  // ---------- RECOVERY / FATIGUE LOGIC ----------

  Map<MuscleGroup, _RecoveryInfo> _computeRecovery(
    List<WorkoutSession> allSessions,
  ) {
    final now = DateTime.now();
    const tauDays = 2.0; // recovery time constant ~2 days

    final Map<MuscleGroup, List<Map<String, dynamic>>> loadsByGroup = {};

    for (final s in allSessions) {
      final Map<MuscleGroup, double> sessionLoad = {};

      for (final we in s.exercises) {
        double load = 0;
        for (final set in we.sets) {
          if (set.weight != null) {
            load += set.weight! * set.reps;
          } else {
            load += set.reps.toDouble(); // bodyweight: count reps
          }
        }
        if (load <= 0) continue;

        final g = we.exercise.group;
        sessionLoad[g] = (sessionLoad[g] ?? 0) + load;
      }

      sessionLoad.forEach((group, load) {
        loadsByGroup.putIfAbsent(group, () => []);
        loadsByGroup[group]!.add({
          'date': s.date,
          'load': load,
        });
      });
    }

    final result = <MuscleGroup, _RecoveryInfo>{};

    loadsByGroup.forEach((group, sessions) {
      if (sessions.isEmpty) return;

      sessions.sort((a, b) =>
          (a['date'] as DateTime).compareTo(b['date'] as DateTime));

      final loads =
          sessions.map((m) => (m['load'] as num).toDouble()).toList();
      final dates =
          sessions.map((m) => m['date'] as DateTime).toList();

      final avgLoad =
          loads.reduce((a, b) => a + b) / loads.length.toDouble();

      double score = 0;
      double? daysSinceLast;

      for (var i = 0; i < loads.length; i++) {
        final date = dates[i];
        final load = loads[i];
        final diffHours = now.difference(date).inHours.toDouble();
        final daysAgo = diffHours / 24.0;

        if (daysAgo < 0) continue;

        if (i == loads.length - 1) {
          daysSinceLast = daysAgo;
        }

        final normalizedLoad = avgLoad > 0 ? load / avgLoad : 1.0;
        final decay = math.exp(-daysAgo / tauDays);

        score += normalizedLoad * decay;
      }

      RecoveryStatus status;
      if (score < 0.5) {
        status = RecoveryStatus.fresh;
      } else if (score < 1.5) {
        status = RecoveryStatus.ok;
      } else {
        status = RecoveryStatus.fatigued;
      }

      result[group] = _RecoveryInfo(
        score: score,
        daysSinceLast: daysSinceLast,
        status: status,
      );
    });

    return result;
  }

  String _recoveryStatusLabel(RecoveryStatus s) {
    switch (s) {
      case RecoveryStatus.fresh:
        return 'Fresh';
      case RecoveryStatus.ok:
        return 'OK';
      case RecoveryStatus.fatigued:
        return 'Fatigued';
    }
  }

  Color _recoveryStatusColor(
    RecoveryStatus s,
    ThemeData theme,
  ) {
    switch (s) {
      case RecoveryStatus.fresh:
        return Colors.green.shade600;
      case RecoveryStatus.ok:
        return theme.colorScheme.primary;
      case RecoveryStatus.fatigued:
        return Colors.red.shade600;
    }
  }

  String _daysSinceLabel(double? days) {
    if (days == null) return 'never';
    if (days < 0.75) return 'today';
    if (days < 1.5) return 'yesterday';
    return '${days.round()} days ago';
  }

  Widget _buildRecoverySection(
    BuildContext context,
    Map<MuscleGroup, _RecoveryInfo> recData,
  ) {
    final theme = Theme.of(context);

    if (recData.isEmpty) {
      return const Text(
        'No recovery data yet. Log some workouts first.',
      );
    }

    final entries = recData.entries.toList()
      ..sort((a, b) => b.value.score.compareTo(a.value.score));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recovery status (based on recent load)',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Higher score = more fatigue. Uses all your past workouts with an exponential decay (~2 days).',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Column(
          children: entries.map((entry) {
            final group = entry.key;
            final info = entry.value;
            final color = _recoveryStatusColor(info.status, theme);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 10,
                  backgroundColor: color,
                ),
                title: Text(muscleGroupLabel(group)),
                subtitle: Text(
                  '${_recoveryStatusLabel(info.status)}'
                  ' • last trained ${_daysSinceLabel(info.daysSinceLast)}'
                  ' • score ${info.score.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ---------- TOP IMPROVING LIFTS ----------

  _LiftTrendResult? _computeSeriesTrend(
    Exercise exercise,
    List<double> values,
  ) {
    if (values.length < 3) return null;

    final n = values.length;

    int k = math.min(3, n ~/ 2);
    if (k == 0) k = 1;

    final recent = values.sublist(n - k);
    final previous = values.sublist(n - 2 * k, n - k);

    double avgRecent =
        recent.reduce((a, b) => a + b) / recent.length.toDouble();
    double avgPrev =
        previous.reduce((a, b) => a + b) / previous.length.toDouble();

    if (avgPrev == 0) return null;

    final diff = avgRecent - avgPrev;
    final rel = diff / avgPrev;

    const upThreshold = 0.05; // +5%

    if (rel <= upThreshold) return null; // only keep clearly improving

    return _LiftTrendResult(
      exercise: exercise,
      deltaAbs: diff,
      deltaRel: rel,
    );
  }

  List<_LiftTrendResult> _computeTopImprovingLifts(
    List<WorkoutSession> allSessions, {
    int maxLifts = 3,
  }) {
    if (allSessions.isEmpty) return [];

    final sorted = List<WorkoutSession>.from(allSessions)
      ..sort((a, b) => a.date.compareTo(b.date));

    final Map<String, Exercise> exMeta = {};
    final Map<String, List<double>> series = {};

    for (final s in sorted) {
      final Map<String, double> sessionMax = {};

      for (final we in s.exercises) {
        exMeta[we.exercise.id] = we.exercise;

        double maxW = sessionMax[we.exercise.id] ?? 0;
        for (final set in we.sets) {
          if (set.weight != null && set.weight! > maxW) {
            maxW = set.weight!;
          }
        }
        if (maxW > 0) {
          sessionMax[we.exercise.id] = maxW;
        }
      }

      sessionMax.forEach((id, maxW) {
        series.putIfAbsent(id, () => []);
        series[id]!.add(maxW);
      });
    }

    final results = <_LiftTrendResult>[];

    series.forEach((id, values) {
      final ex = exMeta[id];
      if (ex == null) return;
      final trend = _computeSeriesTrend(ex, values);
      if (trend != null) {
        results.add(trend);
      }
    });

    results.sort((a, b) => b.deltaRel.compareTo(a.deltaRel));

    if (results.length > maxLifts) {
      return results.sublist(0, maxLifts);
    }
    return results;
  }

  Widget _buildTopImprovingLiftsSection(
    BuildContext context,
    List<_LiftTrendResult> lifts,
  ) {
    final theme = Theme.of(context);

    if (lifts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top improving lifts',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Based on max weight trends over your recent sessions.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Column(
          children: lifts.map((l) {
            final relPct = l.deltaRel * 100;
            final sign = l.deltaAbs >= 0 ? '+' : '';
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(
                  Icons.trending_up,
                  color: Colors.green,
                ),
                title: Text(l.exercise.name),
                subtitle: Text(
                  '$sign${l.deltaAbs.toStringAsFixed(1)} kg '
                  '(${sign}${relPct.toStringAsFixed(1)}%) '
                  'recent vs previous sessions',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ---------- BUILD ----------

  @override
  Widget build(BuildContext context) {
    if (widget.sessions.isEmpty) {
      return const Center(
        child: Text('Log some workouts to see stats.'),
      );
    }

    final theme = Theme.of(context);
    final filtered = _filteredSessions;

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No workouts in this ${_rangeLabel(_range).toLowerCase()}.',
        ),
      );
    }

    final muscleData = _setsPerMuscleGroup(filtered);

    final totalSessions = filtered.length;
    final totalSets = filtered.fold<int>(
      0,
      (sum, s) =>
          sum +
          s.exercises.fold<int>(
            0,
            (sumEx, we) => sumEx + we.sets.length,
          ),
    );

    int muscleMax = 1;
    if (muscleData.values.isNotEmpty) {
      muscleMax =
          muscleData.values.reduce((a, b) => a > b ? a : b);
    }

    final exercises = _availableExercises(filtered);
    Exercise? selectedExercise;

    if (exercises.isNotEmpty) {
      if (_selectedExerciseId != null) {
        selectedExercise = exercises.firstWhere(
          (e) => e.id == _selectedExerciseId,
          orElse: () => exercises.first,
        );
      } else {
        selectedExercise = exercises.first;
      }
    }

    final trendData = selectedExercise == null
        ? <_ExerciseTrendPoint>[]
        : _exerciseTrendData(filtered, selectedExercise.id);

    // Recovery + top lifts use ALL sessions
    final recoveryData = _computeRecovery(widget.sessions);
    final topLifts = _computeTopImprovingLifts(widget.sessions);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stats (${_rangeLabel(_range)})',
                style: theme.textTheme.titleLarge,
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Export CSV',
                    icon: const Icon(Icons.download),
                    onPressed: () => _exportCsv(filtered),
                  ),
                  IconButton(
                    tooltip: 'Clear all data',
                    icon: const Icon(Icons.delete_forever),
                    onPressed: _confirmClearAll,
                  ),
                  DropdownButton<TimeRange>(
                    value: _range,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _range = value);
                    },
                    items: TimeRange.values.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Text(_rangeLabel(r)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$totalSessions workouts • $totalSets sets',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              children: [
                // --- Sets per muscle group ---
                Text(
                  'Sets per muscle group',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (muscleData.isEmpty)
                  const Text(
                      'No muscle-group data for this range.\n(You may have workouts with zero sets.)')
                else
                  Column(
                    children: muscleData.entries.map((entry) {
                      final pct = entry.value / muscleMax;
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${muscleGroupLabel(entry.key)} • ${entry.value} sets',
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 24),

                if (muscleData.isNotEmpty) ...[
                  _buildBodyHeatMap(context, muscleData),
                  const SizedBox(height: 24),
                ],

                // --- Recovery status ---
                _buildRecoverySection(context, recoveryData),
                const SizedBox(height: 24),

                // --- Top improving lifts ---
                _buildTopImprovingLiftsSection(context, topLifts),
                if (topLifts.isNotEmpty)
                  const SizedBox(height: 24),

                // --- Exercise trend selector ---
                Text(
                  'Exercise trend',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),

                if (exercises.isEmpty)
                  const Text(
                    'No exercises with sets in this range.',
                  )
                else ...[
                  _buildExerciseChips(exercises, selectedExercise),
                  const SizedBox(height: 16),
                  if (selectedExercise != null)
                    Text(
                      selectedExercise.name,
                      style: theme.textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 8),

                  // Max weight
                  Text(
                    'Max weight over time',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: _buildLineChart(
                      data: trendData,
                      valueSelector: (p) => p.maxWeight,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Volume
                  Text(
                    'Volume (weight × reps) over time',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: _buildLineChart(
                      data: trendData,
                      valueSelector: (p) => p.volume,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
