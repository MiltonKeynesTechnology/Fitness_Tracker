// lib/screens/workout_detail_screen.dart

import 'package:flutter/material.dart';

import '../models.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final WorkoutSession session;
  final List<Exercise> allExercises;
  final VoidCallback onSessionsChanged;
  final void Function(Exercise) onAddExercise;
  final void Function(WorkoutSession) onDeleteSession;

  const WorkoutDetailScreen({
    super.key,
    required this.session,
    required this.allExercises,
    required this.onSessionsChanged,
    required this.onAddExercise,
    required this.onDeleteSession,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late TextEditingController _nameController;

  WorkoutSession get _session => widget.session;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _session.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateName(String value) {
    setState(() {
      _session.name = value.trim().isEmpty ? _session.name : value.trim();
    });
    widget.onSessionsChanged();
  }

  void _addExercise(Exercise exercise) {
    setState(() {
      _session.exercises.add(
        WorkoutExercise(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          exercise: exercise,
          sets: [
            ExerciseSet(reps: 0, weight: null),
          ],
        ),
      );
    });
    widget.onSessionsChanged();
  }

  void _markCompleted() {
  setState(() {
    _session.status = WorkoutStatus.completed;
  });
  widget.onSessionsChanged();
  }

  void _removeExercise(WorkoutExercise we) {
    setState(() {
      _session.exercises.removeWhere((x) => x.id == we.id);
    });
    widget.onSessionsChanged();
  }

  void _addSet(WorkoutExercise we) {
    setState(() {
      we.sets.add(ExerciseSet(reps: 0, weight: null));
    });
    widget.onSessionsChanged();
  }

  void _removeSet(WorkoutExercise we, int index) {
    setState(() {
      if (index >= 0 && index < we.sets.length) {
        we.sets.removeAt(index);
      }
    });
    widget.onSessionsChanged();
  }

  Future<void> _showAddExerciseSheet() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final all = List<Exercise>.from(widget.allExercises)
          ..sort((a, b) => a.name.compareTo(b.name));

        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: bottomInset + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  const Text(
                    'Add exercise to this workout',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (all.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No exercises yet. Create one first.'),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: all.length,
                      itemBuilder: (context, index) {
                        final e = all[index];
                        return ListTile(
                          title: Text(e.name),
                          subtitle: Text(
                            '${bodyRegionLabel(e.region)} • ${muscleGroupLabel(e.group)}'
                            '${e.subGroup != null ? ' • ${e.subGroup}' : ''}',
                          ),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _addExercise(e);
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showCreateExerciseDialog();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create new exercise'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCreateExerciseDialog() {
    final nameController = TextEditingController();
    final subGroupController = TextEditingController();
    BodyRegion selectedRegion = BodyRegion.upper;
    MuscleGroup selectedGroup = MuscleGroup.midChest;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('New exercise'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<BodyRegion>(
                      value: selectedRegion,
                      decoration: const InputDecoration(
                        labelText: 'Body region',
                      ),
                      items: BodyRegion.values.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(bodyRegionLabel(r)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedRegion = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<MuscleGroup>(
                      value: selectedGroup,
                      decoration: const InputDecoration(
                        labelText: 'Primary muscle',
                      ),
                      items: MuscleGroup.values.map((g) {
                        return DropdownMenuItem(
                          value: g,
                          child: Text(muscleGroupLabel(g)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedGroup = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: subGroupController,
                      decoration: const InputDecoration(
                        labelText: 'Extra info (optional)',
                        hintText: 'e.g. Neutral grip, Cable',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final sub = subGroupController.text.trim();
                    final newEx = Exercise(
                      id: DateTime.now()
                          .millisecondsSinceEpoch
                          .toString(),
                      name: name,
                      region: selectedRegion,
                      group: selectedGroup,
                      subGroup: sub.isEmpty ? null : sub,
                    );

                    widget.onAddExercise(newEx);
                    _addExercise(newEx);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteWorkout() async {
    final result = await showDialog<bool>(
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

    if (result == true) {
      widget.onDeleteSession(_session);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = _session.date;
    final dateStr =
        '${date.day}/${date.month}/${date.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout details'),
        actions: [
          IconButton(
            onPressed: _confirmDeleteWorkout,
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete workout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Name + date
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Workout name',
                    ),
                    onSubmitted: _updateName,
                    onChanged: (val) {
                      _session.name = val;
                      widget.onSessionsChanged();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(dateStr),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(workoutStatusLabel(_session.status)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_session.status == WorkoutStatus.planned)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is a planned workout. When you\'re done logging sets, mark it as completed.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _markCompleted,
                      icon: const Icon(Icons.check),
                      label: const Text('Mark completed'),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 4),

            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _showAddExerciseSheet,
                icon: const Icon(Icons.add),
                label: const Text('Add exercise'),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _session.exercises.isEmpty
                  ? Center(
                      child: Text(
                        'No exercises logged in this workout.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _session.exercises.length,
                      itemBuilder: (context, index) {
                        final we = _session.exercises[index];
                        return Card(
                          margin:
                              const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        we.exercise.name,
                                        style: theme
                                            .textTheme.titleMedium,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _removeExercise(we),
                                      icon: const Icon(Icons.delete),
                                      tooltip: 'Remove exercise',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Column(
                                  children: [
                                    for (var i = 0;
                                        i < we.sets.length;
                                        i++)
                                      _buildSetRow(we, i),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: () => _addSet(we),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add set'),
                                  ),
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

  Widget _buildSetRow(WorkoutExercise we, int index) {
    final set = we.sets[index];

    final repsController = TextEditingController(
      text: set.reps == 0 ? '' : set.reps.toString(),
    );
    final weightController = TextEditingController(
      text: set.weight?.toString() ?? '',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('Set ${index + 1}'),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Reps',
                isDense: true,
              ),
              onChanged: (value) {
                final r = int.tryParse(value);
                if (r != null && r > 0) {
                  set.reps = r;
                } else {
                  set.reps = 0;
                }
                widget.onSessionsChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: TextField(
              controller: weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'kg',
                isDense: true,
              ),
              onChanged: (value) {
                if (value.trim().isEmpty) {
                  set.weight = null;
                } else {
                  final w = double.tryParse(value);
                  if (w != null && w >= 0) {
                    set.weight = w;
                  }
                }
                widget.onSessionsChanged();
              },
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _removeSet(we, index),
            icon: const Icon(Icons.close),
            tooltip: 'Remove set',
          ),
        ],
      ),
    );
  }
}
