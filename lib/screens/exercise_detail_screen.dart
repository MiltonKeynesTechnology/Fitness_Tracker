// lib/screens/exercise_detail_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;
  final List<WorkoutSession> sessions;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    // All sessions that include this exercise
    final filtered = sessions
        .where((s) =>
            s.exercises.any((we) => we.exercise.id == exercise.id))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final data = _buildTrendData(filtered, exercise.id);

    final theme = Theme.of(context);

    final weightValues = data.map((p) => p.maxWeight).toList();
    final volumeValues = data.map((p) => p.volume).toList();

    final weightTrend = _computeTrend(weightValues);
    final volumeTrend = _computeTrend(volumeValues);

    final prInfo = _computePrInfo(weightValues);

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: filtered.isEmpty
            ? const Center(
                child: Text('No sets logged for this exercise yet.'),
              )
            : ListView(
                children: [
                  // -------- PROGRESSION SUMMARY --------
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
                          // Strength (max weight) trend
                          _buildTrendRow(
                            context: context,
                            label: 'Strength (max weight)',
                            trend: weightTrend,
                            unit: 'kg',
                          ),
                          const SizedBox(height: 8),

                          // Volume trend
                          _buildTrendRow(
                            context: context,
                            label: 'Volume (weight × reps)',
                            trend: volumeTrend,
                            unit: '',
                          ),
                          const SizedBox(height: 8),

                          // PR info
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

                  // -------- MAX WEIGHT CHART --------
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

                  // -------- VOLUME CHART --------
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
}

// ---- DATA STRUCTURES & HELPERS ----

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
          // bodyweight
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

  // Use last k vs previous k (k <= 3 and 2k <= n)
  int k = math.min(3, n ~/ 2);
  if (k == 0) k = 1; // extra safety

  final recent = values.sublist(n - k);
  final previous = values.sublist(n - 2 * k, n - k);

  double avgRecent =
      recent.reduce((a, b) => a + b) / recent.length.toDouble();
  double avgPrev =
      previous.reduce((a, b) => a + b) / previous.length.toDouble();

  if (avgPrev == 0) {
    // Hard to define relative change; call it unknown
    return const _TrendResult(
      direction: TrendDirection.unknown,
      deltaAbs: null,
      deltaRel: null,
      enoughData: false,
    );
  }

  final diff = avgRecent - avgPrev;
  final rel = diff / avgPrev;

  const upThreshold = 0.05; // +5%
  const downThreshold = -0.05; // -5%

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

String? _computePrInfo(List<double> weightValues) {
  if (weightValues.length < 2) return null;

  final n = weightValues.length;
  final last = weightValues.last;

  final prevBest =
      weightValues.sublist(0, n - 1).reduce((a, b) => a > b ? a : b);

  if (last > prevBest + 0.25) {
    final diff = last - prevBest;
    return 'New PR last session: ${last.toStringAsFixed(1)} kg '
        '(+${diff.toStringAsFixed(1)} kg over previous best ${prevBest.toStringAsFixed(1)} kg).';
  }

  return 'Current all-time best: ${prevBest.toStringAsFixed(1)} kg.';
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
