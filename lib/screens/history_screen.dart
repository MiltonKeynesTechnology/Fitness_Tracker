// lib/screens/history_screen.dart

import 'package:flutter/material.dart';

import '../models.dart';
import 'workout_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final List<Exercise> exercises;

  /// Called whenever an existing session is edited
  /// (sets changed, name changed, exercises added/removed, etc.).
  final VoidCallback onSessionsChanged;

  /// Called when a new exercise is created from within history / detail.
  final void Function(Exercise) onAddExercise;

  /// Called when a whole workout session is deleted.
  final void Function(WorkoutSession) onDeleteSession;

  const HistoryScreen({
    super.key,
    required this.sessions,
    required this.exercises,
    required this.onSessionsChanged,
    required this.onAddExercise,
    required this.onDeleteSession,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const Center(
        child: Text('No workouts logged yet.'),
      );
    }

    final sorted = List<WorkoutSession>.from(sessions)
      ..sort((a, b) => b.date.compareTo(a.date)); // newest first

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: ListView.builder(
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final s = sorted[index];
          final totalSets = s.exercises.fold<int>(
            0,
            (sum, we) => sum + we.sets.length,
          );

          final date = s.date;
          final dateStr =
              '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/'
              '${date.year}';

          return Dismissible(
            key: ValueKey(s.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete workout?'),
                  content: const Text(
                    'This will delete this workout and all its sets.\n'
                    'This cannot be undone.',
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
            },
            onDismissed: (_) {
              onDeleteSession(s);
            },
            child: ListTile(
              title: Text(s.name.isEmpty ? 'Workout' : s.name),
              subtitle: Text(
                '$dateStr • '
                '${s.exercises.length} exercise${s.exercises.length == 1 ? '' : 's'}'
                ' • $totalSets set${totalSets == 1 ? '' : 's'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WorkoutDetailScreen(
                      session: s,
                      allExercises: exercises,
                      onSessionsChanged: onSessionsChanged,
                      onAddExercise: onAddExercise,
                      onDeleteSession: onDeleteSession,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
