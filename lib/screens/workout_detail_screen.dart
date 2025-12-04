// lib/screens/workout_detail_screen.dart
import 'package:flutter/material.dart';
import '../models.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final WorkoutSession session;
  final List<Exercise> allExercises;
  final void Function(Exercise) onAddExercise;
  final VoidCallback? onChanged;
  final void Function(WorkoutSession) onDeleteSession; 

  const WorkoutDetailScreen({
    super.key,
    required this.session,
    required this.allExercises,
    required this.onAddExercise,
    required this.onChanged,
    required this.onDeleteSession,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.session.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateName(String value) {
    widget.session.name = value.trim();
    widget.onChanged?.call();
  }

    Future<void> _confirmDeleteWorkout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete workout?'),
        content: const Text(
          'This will delete the entire workout and all its sets.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      widget.onDeleteSession(widget.session);
      widget.onChanged?.call();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _editSet(
    WorkoutExercise we,
    int index,
  ) async {
    final set = we.sets[index];
    final repsController =
        TextEditingController(text: set.reps.toString());
    final weightController =
        TextEditingController(text: set.weight?.toString() ?? '');

    final result = await showDialog<WorkoutSet>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit set ${index + 1}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Reps'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Weight (kg, optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final reps = int.tryParse(repsController.text);
                final weight =
                    double.tryParse(weightController.text);
                if (reps == null || reps <= 0) {
                  return;
                }
                Navigator.of(context).pop(
                  WorkoutSet(reps: reps, weight: weight),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        we.sets[index] = result;
      });
      widget.onChanged?.call();
    }
  }

  void _deleteSet(WorkoutExercise we, int index) {
    setState(() {
      we.sets.removeAt(index);
    });
    widget.onChanged?.call();
  }

  Future<void> _addSet(WorkoutExercise we) async {
    final repsController = TextEditingController();
    final weightController = TextEditingController();

    final result = await showDialog<WorkoutSet>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add set (${we.exercise.name})'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Reps'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Weight (kg, optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final reps = int.tryParse(repsController.text);
                final weight =
                    double.tryParse(weightController.text);
                if (reps == null || reps <= 0) return;
                Navigator.of(context).pop(
                  WorkoutSet(reps: reps, weight: weight),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        we.sets.add(result);
      });
      widget.onChanged?.call();
    }
  }

  Future<void> _addExerciseToWorkout() async {
    Exercise? selected;
    final nameController = TextEditingController();
    BodyRegion region = BodyRegion.upper;
    MuscleGroup group = MuscleGroup.chest;
    final subGroupController = TextEditingController();

    final result = await showDialog<WorkoutExercise>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add exercise to workout'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Choose existing
                    DropdownButtonFormField<Exercise>(
                      initialValue: selected,
                      decoration: const InputDecoration(
                        labelText: 'Existing exercise (optional)',
                      ),
                      items: widget.allExercises
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          selected = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text('Or create new:'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'New exercise name',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<BodyRegion>(
                      initialValue: region,
                      decoration: const InputDecoration(
                        labelText: 'Body region',
                      ),
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
                    const SizedBox(height: 8),
                    DropdownButtonFormField<MuscleGroup>(
                      initialValue: group,
                      decoration: const InputDecoration(
                        labelText: 'Muscle group',
                      ),
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
                    const SizedBox(height: 8),
                    TextField(
                      controller: subGroupController,
                      decoration: const InputDecoration(
                        labelText: 'Sub-group (optional)',
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
                    Exercise exercise;
                    if (selected != null) {
                      exercise = selected!;
                    } else {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      exercise = Exercise(
                        id: '${DateTime.now().microsecondsSinceEpoch}',
                        name: name,
                        region: region,
                        group: group,
                        subGroup: subGroupController.text.trim().isEmpty
                            ? null
                            : subGroupController.text.trim(),
                      );
                      widget.onAddExercise(exercise); // add to global list
                    }
                    Navigator.of(context).pop(
                      WorkoutExercise(exercise: exercise),
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        widget.session.exercises.add(result);
      });
      widget.onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final dateStr =
        '${s.date.day.toString().padLeft(2, '0')}.${s.date.month.toString().padLeft(2, '0')}.${s.date.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete workout',
            onPressed: _confirmDeleteWorkout,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add exercise',
            onPressed: _addExerciseToWorkout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: $dateStr'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Workout name',
              ),
              onChanged: _updateName,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: s.exercises.isEmpty
                  ? const Center(
                      child: Text('No exercises in this workout yet.'),
                    )
                  : ListView.builder(
                      itemCount: s.exercises.length,
                      itemBuilder: (context, index) {
                        final we = s.exercises[index];
                        final totalReps = we.sets.fold<int>(
                          0,
                          (sum, set) => sum + set.reps,
                        );
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      tooltip: 'Add set',
                                      onPressed: () => _addSet(we),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (we.sets.isEmpty)
                                  const Text(
                                    'No sets yet. Tap + to add one.',
                                  )
                                else
                                  Column(
                                    children:
                                        List.generate(we.sets.length, (i) {
                                      final set = we.sets[i];
                                      return ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                            'Set ${i + 1}: ${set.reps} reps'),
                                        subtitle: Text(set.weight != null
                                            ? '${set.weight} kg'
                                            : 'Bodyweight'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () =>
                                                  _editSet(we, i),
                                            ),
                                            IconButton(
                                              icon:
                                                  const Icon(Icons.delete),
                                              onPressed: () =>
                                                  _deleteSet(we, i),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                const SizedBox(height: 4),
                                if (we.sets.isNotEmpty)
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
          ],
        ),
      ),
    );
  }
}
