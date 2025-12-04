import 'package:flutter/material.dart';
import '../models.dart';

class TodayScreen extends StatefulWidget {
  final List<Exercise> exercises;
  final void Function(WorkoutSession) onSaveSession;
  final void Function(Exercise) onAddExercise;

  const TodayScreen({
    super.key,
    required this.exercises,
    required this.onSaveSession,
    required this.onAddExercise,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final TextEditingController _nameController = TextEditingController();
  Exercise? _selectedExercise;

  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  final List<WorkoutExercise> _workoutExercises = [];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _nameController.text =
        'Workout ${today.day.toString().padLeft(2, '0')}.${today.month.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  WorkoutExercise _getOrCreateWorkoutExercise(Exercise exercise) {
    final existing = _workoutExercises
        .where((we) => we.exercise.id == exercise.id)
        .toList();
    if (existing.isNotEmpty) return existing.first;

    final newWE = WorkoutExercise(exercise: exercise);
    _workoutExercises.add(newWE);
    return newWE;
  }

  void _addSet() {
    if (_selectedExercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an exercise first.')),
      );
      return;
    }

    final reps = int.tryParse(_repsController.text);
    final weight = double.tryParse(_weightController.text);

    if (reps == null || reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid reps.')),
      );
      return;
    }

    final we = _getOrCreateWorkoutExercise(_selectedExercise!);
    setState(() {
      we.sets.add(WorkoutSet(reps: reps, weight: weight));
      _repsController.clear();
      _weightController.clear();
    });
  }

  void _saveSession() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name your workout.')),
      );
      return;
    }

    if (_workoutExercises.isEmpty ||
        _workoutExercises.every((we) => we.sets.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one exercise with sets.'),
        ),
      );
      return;
    }

    final session = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      name: name,
      exercises: _workoutExercises
          .map((we) => WorkoutExercise(
                exercise: we.exercise,
                sets: List.of(we.sets),
              ))
          .toList(),
    );

    widget.onSaveSession(session);

    setState(() {
      _workoutExercises.clear();
      _repsController.clear();
      _weightController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout saved!')),
    );
  }

  Future<void> _showAddExerciseDialog() async {
    final nameController = TextEditingController();
    BodyRegion region = BodyRegion.upper;
    MuscleGroup group = MuscleGroup.chest;
    final subGroupController = TextEditingController();

    final result = await showDialog<Exercise>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Exercise'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Exercise name',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BodyRegion>(
                  initialValue: region,
                  decoration: const InputDecoration(labelText: 'Body region'),
                  items: BodyRegion.values
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(bodyRegionLabel(r)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      region = value;
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MuscleGroup>(
                  initialValue: group,
                  decoration: const InputDecoration(labelText: 'Muscle group'),
                  items: MuscleGroup.values
                      .map(
                        (g) => DropdownMenuItem(
                          value: g,
                          child: Text(muscleGroupLabel(g)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      group = value;
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subGroupController,
                  decoration: const InputDecoration(
                    labelText: 'Sub-group (optional)',
                    hintText: 'Rear delts, Quads, etc.',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final ex = Exercise(
                  id: '${DateTime.now().microsecondsSinceEpoch}',
                  name: name,
                  region: region,
                  group: group,
                  subGroup: subGroupController.text.trim().isEmpty
                      ? null
                      : subGroupController.text.trim(),
                );
                Navigator.of(context).pop(ex);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      widget.onAddExercise(result);
      setState(() {
        _selectedExercise = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr =
        '${today.day.toString().padLeft(2, '0')}.${today.month.toString().padLeft(2, '0')}.${today.year}';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today • $dateStr',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Workout name (e.g. Push A, Legs Heavy)',
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Exercise>(
                  initialValue: _selectedExercise,
                  decoration: const InputDecoration(labelText: 'Exercise'),
                  items: widget.exercises.map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Text(e.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedExercise = value);
                  },
                ),
              ),
              IconButton(
                onPressed: _showAddExerciseDialog,
                icon: const Icon(Icons.add),
                tooltip: 'New exercise',
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Reps'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Weight (kg, optional)'),
                ),
              ),
              IconButton(
                onPressed: _addSet,
                icon: const Icon(Icons.add),
                tooltip: 'Add set',
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: _workoutExercises.isEmpty
                ? const Center(
                    child: Text('No exercises added yet.'),
                  )
                : ListView.builder(
                    itemCount: _workoutExercises.length,
                    itemBuilder: (context, index) {
                      final we = _workoutExercises[index];
                      final totalReps = we.sets.fold<int>(
                        0,
                        (sum, s) => sum + s.reps,
                      );
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                we.exercise.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                              Text(
                                '${muscleGroupLabel(we.exercise.group)}'
                                '${we.exercise.subGroup != null ? ' • ${we.exercise.subGroup}' : ''}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Column(
                                children: List.generate(we.sets.length, (i) {
                                  final s = we.sets[i];
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                          'Set ${i + 1}: ${s.reps} reps'),
                                      Text(s.weight != null
                                          ? '${s.weight} kg'
                                          : 'Bodyweight'),
                                    ],
                                  );
                                }),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total reps: $totalReps',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saveSession,
              child: const Text('Save Workout'),
            ),
          ),
        ],
      ),
    );
  }
}
