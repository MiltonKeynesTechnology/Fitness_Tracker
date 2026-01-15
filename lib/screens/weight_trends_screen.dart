// lib/screens/weight_trends_screen.dart

import 'package:flutter/material.dart';
import '../models.dart';

class WeightTrendsScreen extends StatefulWidget {
  final List<WeightEntry> weightEntries;

  const WeightTrendsScreen({
    super.key,
    required this.weightEntries,
  });

  @override
  State<WeightTrendsScreen> createState() => _WeightTrendsScreenState();
}

enum WeightRange { week, month, year }

class _WeightTrendsScreenState extends State<WeightTrendsScreen> {
  WeightRange _range = WeightRange.month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    // --- pick time range ---
    DateTime from;
    switch (_range) {
      case WeightRange.week:
        from = now.subtract(const Duration(days: 7));
        break;
      case WeightRange.month:
        from = now.subtract(const Duration(days: 30));
        break;
      case WeightRange.year:
        from = now.subtract(const Duration(days: 365));
        break;
    }

    // --- filter + group by day (one entry per day) ---
    final Map<DateTime, WeightEntry> byDay = {};

    for (final w in widget.weightEntries) {
      if (w.date.isBefore(from)) continue;

      // normalise to "day only"
      final dayKey = DateTime(w.date.year, w.date.month, w.date.day);

      final existing = byDay[dayKey];
      if (existing == null || w.date.isAfter(existing.date)) {
        // keep the latest entry for that day
        byDay[dayKey] = w;
      }
    }

// turn back into a sorted list
final data = byDay.entries
    .map((e) => e.value)
    .toList()
  ..sort((a, b) => a.date.compareTo(b.date));

final values = data.map((w) => w.weightKg).toList();

    double? delta;
    double? average;
    double? minV;
    double? maxV;

    if (values.isNotEmpty) {
      minV = values.reduce((a, b) => a < b ? a : b);
      maxV = values.reduce((a, b) => a > b ? a : b);
      average = values.reduce((a, b) => a + b) / values.length;
      if (values.length >= 2) {
        delta = values.last - values.first;
      }
    }

    String _rangeLabel() {
      switch (_range) {
        case WeightRange.week:
          return 'Last 7 days';
        case WeightRange.month:
          return 'Last 30 days';
        case WeightRange.year:
          return 'Last 12 months';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight trends'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- range selector ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Week'),
                  selected: _range == WeightRange.week,
                  onSelected: (_) {
                    setState(() => _range = WeightRange.week);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Month'),
                  selected: _range == WeightRange.month,
                  onSelected: (_) {
                    setState(() => _range = WeightRange.month);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Year'),
                  selected: _range == WeightRange.year,
                  onSelected: (_) {
                    setState(() => _range = WeightRange.year);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _rangeLabel(),
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),

            // --- big chart card ---
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: values.length < 2
                      ? Center(
                          child: Text(
                            'Not enough data yet for this range.',
                            style: theme.textTheme.bodySmall,
                          ),
                        )
                      : CustomPaint(
                          painter: _WeightMetricChartPainter(data),
                          child: Container(),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- stats row ---
            if (values.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Change'),
                          const SizedBox(height: 4),
                          Text(
                            delta == null
                                ? '–'
                                : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: delta == null
                                  ? theme.colorScheme.onSurface
                                  : (delta > 0
                                      ? Colors.redAccent
                                      : Colors.green),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Average'),
                          const SizedBox(height: 4),
                          Text(
                            average == null
                                ? '–'
                                : '${average.toStringAsFixed(1)} kg',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Range'),
                          const SizedBox(height: 4),
                          Text(
                            (minV == null || maxV == null)
                                ? '–'
                                : '${minV.toStringAsFixed(1)} – ${maxV.toStringAsFixed(1)} kg',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Simple line chart for weight
// Simple line chart for weight with axes + smoothing
class _WeightMetricChartPainter extends CustomPainter {
  final List<WeightEntry> data;

  _WeightMetricChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    // --- layout paddings for axes/labels ---
    const double leftPadding = 40;
    const double rightPadding = 16;
    const double topPadding = 12;
    const double bottomPadding = 24;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    // --- data range ---
    final weights = data.map((e) => e.weightKg).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final range = (maxW - minW).abs() < 1e-6 ? 1.0 : (maxW - minW);

    // --- map to points in chart rect ---
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final t = data.length == 1 ? 0.0 : i / (data.length - 1);
      final x = leftPadding + t * chartWidth;
      final yNorm = (data[i].weightKg - minW) / range;
      final y = topPadding + (1 - yNorm) * chartHeight;
      points.add(Offset(x, y));
    }

    // --- draw axes ---
    final axisPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    // y-axis
    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + chartHeight),
      axisPaint,
    );

    // x-axis
    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(leftPadding + chartWidth, topPadding + chartHeight),
      axisPaint,
    );

    // --- y-axis labels (min & max) ---
    final textStyle = TextStyle(
      color: Colors.grey.shade600,
      fontSize: 10,
    );

    final maxTp = TextPainter(
      text: TextSpan(
        text: maxW.toStringAsFixed(1),
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: leftPadding - 4);

    maxTp.paint(
      canvas,
      Offset(leftPadding - maxTp.width - 4, topPadding - maxTp.height / 2),
    );

    final minTp = TextPainter(
      text: TextSpan(
        text: minW.toStringAsFixed(1),
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: leftPadding - 4);

    minTp.paint(
      canvas,
      Offset(
        leftPadding - minTp.width - 4,
        topPadding + chartHeight - minTp.height / 2,
      ),
    );

    // --- x-axis labels (start & end dates) ---
    final start = data.first.date;
    final end = data.last.date;

    String _fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

    final startTp = TextPainter(
      text: TextSpan(text: _fmt(start), style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: chartWidth / 2);

    startTp.paint(
      canvas,
      Offset(leftPadding, topPadding + chartHeight + 4),
    );

    final endTp = TextPainter(
      text: TextSpan(text: _fmt(end), style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: chartWidth / 2);

    endTp.paint(
      canvas,
      Offset(
        leftPadding + chartWidth - endTp.width,
        topPadding + chartHeight + 4,
      ),
    );

    // --- smooth line path using quadratic Beziers ---
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.blueAccent;

    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final mid = Offset(
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
        path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      }
    }

    canvas.drawPath(path, linePaint);

    // --- optional: highlight last point ---
    final lastPoint = points.last;
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blueAccent;
    canvas.drawCircle(lastPoint, 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _WeightMetricChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

