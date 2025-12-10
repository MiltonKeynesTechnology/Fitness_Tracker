// lib/screens/history_screen.dart

import 'package:flutter/material.dart';

import '../models.dart';
import 'workout_detail_screen.dart';
import 'planner_screen.dart';

class HistoryScreen extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final List<Exercise> exercises;

  /// Called when any session changes (name, sets, status, etc.).
  final VoidCallback onSessionsChanged;

  /// Add a brand new exercise from within the detail screen.
  final void Function(Exercise) onAddExercise;

  /// Delete a full workout session.
  final void Function(WorkoutSession) onDeleteSession;

  /// Add a new session (used by the weekly planner).
  final void Function(WorkoutSession) onAddSession;

  const HistoryScreen({
    super.key,
    required this.sessions,
    required this.exercises,
    required this.onSessionsChanged,
    required this.onAddExercise,
    required this.onDeleteSession,
    required this.onAddSession,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('History'),
        ),
        body: const Center(
          child: Text('No workouts yet. Log a session to see history.'),
        ),
      );
    }

    final planned = sessions
        .where((s) => s.status == WorkoutStatus.planned)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date)); // oldest → newest

    final completed = sessions
        .where((s) => s.status == WorkoutStatus.completed)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // newest → oldest

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Plan weeks',
            onPressed: () async {
              final createdCount = await Navigator.of(context).push<int>(
                MaterialPageRoute(
                  builder: (_) => PlannerScreen(
                    existingSessions: sessions,
                    allExercises: exercises, // NEW: allow custom day building
                    onAddSession: onAddSession,
                  ),
                ),
              );

              if (createdCount != null && createdCount > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Planned $createdCount workouts.'),
                  ),
                );
                onSessionsChanged();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (planned.isNotEmpty) ...[
            Text(
              'Planned workouts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...planned.map(
              (s) => _WorkoutTile(
                session: s,
                exercises: exercises,
                isPlanned: true,
                onSessionsChanged: onSessionsChanged,
                onAddExercise: onAddExercise,
                onDeleteSession: onDeleteSession,
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (completed.isNotEmpty) ...[
            Text(
              'Completed workouts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...completed.map(
              (s) => _WorkoutTile(
                session: s,
                exercises: exercises,
                isPlanned: false,
                onSessionsChanged: onSessionsChanged,
                onAddExercise: onAddExercise,
                onDeleteSession: onDeleteSession,
              ),
            ),
          ],

          if (planned.isEmpty && completed.isEmpty)
            const Center(
              child: Text('No workouts to show.'),
            ),
        ],
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  final WorkoutSession session;
  final List<Exercise> exercises;
  final bool isPlanned;
  final VoidCallback onSessionsChanged;
  final void Function(Exercise) onAddExercise;
  final void Function(WorkoutSession) onDeleteSession;

  const _WorkoutTile({
    required this.session,
    required this.exercises,
    required this.isPlanned,
    required this.onSessionsChanged,
    required this.onAddExercise,
    required this.onDeleteSession,
  });

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete workout?'),
        content: Text(
          'Delete "${session.name}" on ${_formatDate(session.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      onDeleteSession(session);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = _formatDate(session.date);
    final totalSets = session.exercises.fold<int>(
      0,
      (sum, we) => sum + we.sets.length,
    );

    String subtitle = dateStr;
    if (totalSets > 0) {
      subtitle += ' • $totalSets sets';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkoutDetailScreen(
                session: session,
                allExercises: exercises,
                onSessionsChanged: onSessionsChanged,
                onAddExercise: onAddExercise,
                onDeleteSession: onDeleteSession,
              ),
            ),
          );
        },
        title: Row(
          children: [
            Expanded(child: Text(session.name)),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                isPlanned ? 'Planned' : 'Completed',
              ),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 0),
            ),
          ],
        ),
        subtitle: Text(subtitle),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmDelete(context),
          tooltip: 'Delete workout',
        ),
      ),
    );
  }
}
