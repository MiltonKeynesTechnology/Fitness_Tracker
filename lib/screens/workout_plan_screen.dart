import 'package:flutter/material.dart';

import '../models.dart';
import 'planner_screen.dart';

class WorkoutPlanScreen extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final List<Exercise> exercises;
  final void Function(WorkoutSession) onAddSession;
  final void Function(WorkoutSession) onDeleteSession;

  const WorkoutPlanScreen({
    super.key,
    required this.sessions,
    required this.exercises,
    required this.onAddSession,
    required this.onDeleteSession,
  });

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = _dateOnly(DateTime.now());
    final end = today.add(const Duration(days: 6));

    final planned = sessions
        .where((s) => s.status == WorkoutStatus.planned)
        .where((s) {
          final d = _dateOnly(s.date);
          return !d.isBefore(today) && !d.isAfter(end);
        })
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Group by day
    final map = <DateTime, List<WorkoutSession>>{};
    for (int i = 0; i < 7; i++) {
      map[today.add(Duration(days: i))] = [];
    }
    for (final s in planned) {
      final d = _dateOnly(s.date);
      map.putIfAbsent(d, () => []);
      map[d]!.add(s);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your workout plan'),
        actions: [
          IconButton(
            tooltip: 'Edit plan',
            icon: const Icon(Icons.edit_calendar),
            onPressed: openPlanner,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Next 7 days',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'This view is built from your scheduled workouts. Tap Edit to change the plan.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ...map.entries.map((entry) {
            final day = entry.key;
            final items = entry.value..sort((a, b) => a.date.compareTo(b.date));

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatDate(day),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          items.isEmpty ? 'Rest / unscheduled' : '${items.length} scheduled',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (items.isEmpty)
                      Text(
                        'No workout planned.',
                        style: theme.textTheme.bodySmall,
                      )
                    else
                      Column(
                        children: items.map((s) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.event_available, size: 18),
                                const SizedBox(width: 8),
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
            );
          }),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: openPlanner,
            icon: const Icon(Icons.edit_calendar),
            label: const Text('Edit plan in planner'),
          ),
        ],
      ),
    );
  }
}
