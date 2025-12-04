// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import '../models.dart';
import 'workout_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final List<Exercise> exercises;
  final VoidCallback onSessionsChanged;
  final void Function(Exercise) onAddExercise;
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

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final s = sessions[index];
        final dateStr =
            '${s.date.day.toString().padLeft(2, '0')}.${s.date.month.toString().padLeft(2, '0')}.${s.date.year}';

        final totalExercises = s.exercises.length;
        final totalSets = s.exercises.fold<int>(
          0,
          (sum, we) => sum + we.sets.length,
        );

        return Card(
          child: ListTile(
            title: Text(s.name),
            subtitle: Text(
              '$dateStr • $totalExercises exercises • $totalSets sets',
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WorkoutDetailScreen(
                    session: s,
                    allExercises: exercises,
                    onAddExercise: onAddExercise,
                    onChanged: onSessionsChanged,
                    onDeleteSession: onDeleteSession,  // 👈 pass it on
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
