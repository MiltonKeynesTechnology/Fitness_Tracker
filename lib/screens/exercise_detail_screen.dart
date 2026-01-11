// lib/screens/exercise_detail_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  final List<WorkoutSession> sessions;
  final void Function(Exercise updated) onUpdateExercise;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    required this.sessions,
    required this.onUpdateExercise,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late Exercise _exercise;

  @override
  void initState() {
    super.initState();
    _exercise = widget.exercise;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.sessions
        .where((s) =>
            s.exercises.any((we) => we.exercise.id == _exercise.id))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final data = _buildTrendData(filtered, _exercise.id);

    final theme = Theme.of(context);

    final weightValues = data.map((p) => p.maxWeight).toList();
    final volumeValues = data.map((p) => p.volume).toList();

    final weightTrend = _computeTrend(weightValues);
    final volumeTrend = _computeTrend(volumeValues);

    final prInfo = _computePrInfo(_exercise, weightValues);

    return Scaffold(
      appBar: AppBar(
        title: Text(_exercise.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: filtered.isEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopButtons(context),
                  const SizedBox(height: 16),
                  _buildGoalSection(context),
                  const SizedBox(height: 24),
                  const Center(
                    child:
                        Text('No sets logged for this exercise yet.'),
                  ),
                ],
              )
            : ListView(
                children: [
                  _buildTopButtons(context),
                  const SizedBox(height: 16),

                  _buildGoalSection(context),
                  const SizedBox(height: 24),

                  Text(
                    'Progression summary',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTrendRow(
                            context: context,
                            label: 'Strength (max weight)',
                            trend: weightTrend,
                            unit: 'kg',
                          ),
                          const SizedBox(height: 8),
                          _buildTrendRow(
                            context: context,
                            label: 'Volume (weight × reps)',
                            trend: volumeTrend,
                            unit: '',
                          ),
                          const SizedBox(height: 8),
                          if (prInfo != null)
                            Text(
                              prInfo,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            Text(
                              'No clear PR yet — keep logging sessions.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Max weight over time',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: _buildLineChart(
                      data: data,
                      valueSelector: (p) => p.maxWeight,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Volume (weight × reps) over time',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: _buildLineChart(
                      data: data,
                      valueSelector: (p) => p.volume,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ---- TOP BUTTONS (PR + GOAL) ----

  Widget _buildTopButtons(BuildContext context) {
    final theme = Theme.of(context);
    final pr = _exercise.manualPr;

    return Row(
      children: [
        FilledButton.icon(
          onPressed: () => _showSetPrDialog(context),
          icon: const Icon(Icons.emoji_events_outlined),
          label: const Text('Set existing PR'),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: () => _showSetGoalDialog(context),
          icon: const Icon(Icons.flag_outlined),
          label: const Text('Set goal'),
        ),
        const SizedBox(width: 12),
        if (pr != null)
          Expanded(
            child: Text(
              'Manual PR: ${pr.toStringAsFixed(1)} kg',
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Future<void> _showSetPrDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: _exercise.manualPr?.toStringAsFixed(1) ?? '',
    );

    final result = await showDialog<double?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Set existing PR'),
          content: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'PR weight (kg)',
              hintText: 'e.g. 120',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  Navigator.of(ctx).pop(null);
                  return;
                }
                final value = double.tryParse(text);
                Navigator.of(ctx).pop(value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    final updated = _exercise.copyWith(manualPr: result);

    setState(() {
      _exercise = updated;
    });

    widget.onUpdateExercise(updated);
  }

  // ---- GOAL SECTION (estimated 1RM) ----

  Widget _buildGoalSection(BuildContext context) {
    final theme = Theme.of(context);
    final goalWeight = _exercise.goalWeight;
    final goalReps = _exercise.goalReps;

    final bestSet = _computeBestSet();

    if (goalWeight == null || goalReps == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Goal',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'No goal set yet. Tap "Set goal" above to define a target '
                'weight and reps (e.g. 100 kg × 5).',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    final goalEst1RM = _estimate1RM(goalWeight, goalReps);

    if (bestSet == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Goal',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Goal: ${goalWeight.toStringAsFixed(1)} kg × $goalReps reps',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'No weighted sets logged yet. '
                'Once you log sets, progress will be based on estimated 1RM '
                '(heavier low-rep sets count more than light high-rep sets).',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    final bestEst1RM = bestSet.est1rm;

    final progressRaw = bestEst1RM / goalEst1RM;
    final progressClamped = progressRaw.clamp(0.0, 1.0);
    final progressPct = progressRaw * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goal',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Goal: ${goalWeight.toStringAsFixed(1)} kg × $goalReps reps',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Best set logged: '
              '${bestSet.weight.toStringAsFixed(1)} kg × ${bestSet.reps} reps\n'
              'Best estimated 1RM: ${bestEst1RM.toStringAsFixed(1)} kg\n'
              'Goal estimated 1RM: ${goalEst1RM.toStringAsFixed(1)} kg\n'
              'Progress: ${progressPct.toStringAsFixed(1)}% towards goal '
              '(based on estimated 1RM).',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressClamped,
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSetGoalDialog(BuildContext context) async {
    final weightController = TextEditingController(
      text: _exercise.goalWeight?.toStringAsFixed(1) ?? '',
    );
    final repsController = TextEditingController(
      text: _exercise.goalReps?.toString() ?? '',
    );

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Set goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Target weight (kg)',
                  hintText: 'e.g. 100',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target reps',
                  hintText: 'e.g. 5',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final wText = weightController.text.trim();
                final rText = repsController.text.trim();

                final weight = double.tryParse(wText);
                final reps = int.tryParse(rText);

                if (weight == null || reps == null || reps <= 0) {
                  Navigator.of(ctx).pop(null);
                  return;
                }

                Navigator.of(ctx).pop({
                  'weight': weight,
                  'reps': reps,
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    final goalWeight = result['weight'] as double;
    final goalReps = result['reps'] as int;

    final updated = _exercise.copyWith(
      goalWeight: goalWeight,
      goalReps: goalReps,
    );

    setState(() {
      _exercise = updated;
    });

    widget.onUpdateExercise(updated);
  }

  // ---- BEST SET (by estimated 1RM) ----

  _BestSetInfo? _computeBestSet() {
    double bestEst1RM = 0;
    double bestWeight = 0;
    int bestReps = 0;

    for (final s in widget.sessions) {
      for (final we in s.exercises) {
        if (we.exercise.id != _exercise.id) continue;

        for (final set in we.sets) {
          if (set.weight == null) continue;
          final w = set.weight!;
          final r = set.reps;
          final est = _estimate1RM(w, r);
          if (est > bestEst1RM) {
            bestEst1RM = est;
            bestWeight = w;
            bestReps = r;
          }
        }
      }
    }

    if (bestEst1RM <= 0) return null;
    return _BestSetInfo(bestWeight, bestReps, bestEst1RM);
  }
}

// ---- SUPPORT TYPES & HELPERS ----

double _estimate1RM(double weight, int reps) {
  final r = reps.clamp(1, 30);
  return weight * (1.0 + r / 30.0);
}

class _BestSetInfo {
  final double weight;
  final int reps;
  final double est1rm;

  _BestSetInfo(this.weight, this.reps, this.est1rm);
}

class _ExerciseTrendPoint {
  final DateTime date;
  final double maxWeight;
  final double volume;

  _ExerciseTrendPoint(this.date, this.maxWeight, this.volume);
}

List<_ExerciseTrendPoint> _buildTrendData(
  List<WorkoutSession> sessions,
  String exerciseId,
) {
  final List<_ExerciseTrendPoint> points = [];

  for (final s in sessions) {
    double maxW = 0;
    double volume = 0;

    for (final we in s.exercises) {
      if (we.exercise.id != exerciseId) continue;
      for (final set in we.sets) {
        if (set.weight != null) {
          if (set.weight! > maxW) maxW = set.weight!;
          volume += set.weight! * set.reps;
        } else {
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

// ---- TREND & PR LOGIC ----

enum TrendDirection { up, down, stable, unknown }

class _TrendResult {
  final TrendDirection direction;
  final double? deltaAbs;
  final double? deltaRel;
  final bool enoughData;

  const _TrendResult({
    required this.direction,
    required this.deltaAbs,
    required this.deltaRel,
    required this.enoughData,
  });
}

_TrendResult _computeTrend(List<double> values) {
  if (values.length < 3) {
    return const _TrendResult(
      direction: TrendDirection.unknown,
      deltaAbs: null,
      deltaRel: null,
      enoughData: false,
    );
  }

  final n = values.length;

  int k = math.min(3, n ~/ 2);
  if (k == 0) k = 1;

  final recent = values.sublist(n - k);
  final previous = values.sublist(n - 2 * k, n - k);

  double avgRecent =
      recent.reduce((a, b) => a + b) / recent.length.toDouble();
  double avgPrev =
      previous.reduce((a, b) => a + b) / previous.length.toDouble();

  if (avgPrev == 0) {
    return const _TrendResult(
      direction: TrendDirection.unknown,
      deltaAbs: null,
      deltaRel: null,
      enoughData: false,
    );
  }

  final diff = avgRecent - avgPrev;
  final rel = diff / avgPrev;

  const upThreshold = 0.05;
  const downThreshold = -0.05;

  TrendDirection dir;
  if (rel > upThreshold) {
    dir = TrendDirection.up;
  } else if (rel < downThreshold) {
    dir = TrendDirection.down;
  } else {
    dir = TrendDirection.stable;
  }

  return _TrendResult(
    direction: dir,
    deltaAbs: diff,
    deltaRel: rel,
    enoughData: true,
  );
}

String? _computePrInfo(Exercise exercise, List<double> weightValues) {
  final manual = exercise.manualPr;

  if (weightValues.isEmpty) {
    if (manual != null) {
      return 'Current all-time best (manual): '
          '${manual.toStringAsFixed(1)} kg.';
    }
    return null;
  }

  final n = weightValues.length;
  final last = weightValues.last;

  double? prevBest;

  if (n >= 2) {
    final prevDataBest = weightValues
        .sublist(0, n - 1)
        .reduce((a, b) => a > b ? a : b);
    prevBest = prevDataBest;
  }

  if (manual != null) {
    prevBest = prevBest == null ? manual : math.max(prevBest, manual);
  }

  if (prevBest == null) {
    return 'Current all-time best: ${last.toStringAsFixed(1)} kg.';
  }

  if (last > prevBest + 0.25) {
    final diff = last - prevBest;
    return 'New PR last session: ${last.toStringAsFixed(1)} kg '
        '(+${diff.toStringAsFixed(1)} kg over previous best '
        '${prevBest.toStringAsFixed(1)} kg).';
  }

  final bestOverall = math.max(prevBest, last);
  if (manual != null && manual > bestOverall) {
    return 'Current all-time best (manual): '
        '${manual.toStringAsFixed(1)} kg.';
  }

  return 'Current all-time best: ${bestOverall.toStringAsFixed(1)} kg.';
}

Widget _buildTrendRow({
  required BuildContext context,
  required String label,
  required _TrendResult trend,
  required String unit,
}) {
  final theme = Theme.of(context);

  IconData icon;
  Color color;
  String text;

  if (!trend.enoughData) {
    icon = Icons.help_outline;
    color = theme.colorScheme.outline;
    text = 'Not enough data yet (need at least 3 sessions).';
  } else {
    switch (trend.direction) {
      case TrendDirection.up:
        icon = Icons.trending_up;
        color = Colors.green.shade600;
        break;
      case TrendDirection.down:
        icon = Icons.trending_down;
        color = Colors.red.shade600;
        break;
      case TrendDirection.stable:
        icon = Icons.trending_flat;
        color = theme.colorScheme.primary;
        break;
      case TrendDirection.unknown:
        icon = Icons.help_outline;
        color = theme.colorScheme.outline;
        break;
    }

    if (trend.deltaAbs != null && trend.deltaRel != null) {
      final sign = trend.deltaAbs! >= 0 ? '+' : '';
      final absStr =
          '${sign}${trend.deltaAbs!.toStringAsFixed(1)}${unit.isNotEmpty ? ' $unit' : ''}';
      final relStr =
          '${sign}${(trend.deltaRel! * 100).toStringAsFixed(1)}%';
      text = 'Recent vs previous: $absStr ($relStr)';
    } else {
      text = 'Trend unclear.';
    }
  }

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 2),
            Text(
              text,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ],
  );
}

// ---- CHART RENDERING ----

Widget _buildLineChart({
  required List<_ExerciseTrendPoint> data,
  required double Function(_ExerciseTrendPoint p) valueSelector,
  required Color color,
}) {
  if (data.isEmpty) {
    return const Center(child: Text('No data.'));
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
