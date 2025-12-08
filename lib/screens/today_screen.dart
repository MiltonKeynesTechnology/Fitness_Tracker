// lib/screens/today_screen.dart

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
  DateTime _selectedDate = DateTime.now();

  final List<WorkoutExercise> _items = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addExerciseToWorkout(Exercise exercise) {
    setState(() {
      _items.add(
        WorkoutExercise(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          exercise: exercise,
          sets: [
            // reps start blank (0 means “unset” in UI)
            ExerciseSet(reps: 0, weight: null),
          ],
        ),
      );
    });
  }

  void _removeExerciseFromWorkout(WorkoutExercise we) {
    setState(() {
      _items.removeWhere((x) => x.id == we.id);
    });
  }

  void _addSet(WorkoutExercise we) {
    setState(() {
      we.sets.add(ExerciseSet(reps: 0, weight: null));
    });
  }

  void _removeSet(WorkoutExercise we, int index) {
    setState(() {
      if (index >= 0 && index < we.sets.length) {
        we.sets.removeAt(index);
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (result != null) {
      setState(() {
        _selectedDate = result;
      });
    }
  }

  Future<void> _showAddExerciseSheet() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final all = List<Exercise>.from(widget.exercises)
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
                            _addExerciseToWorkout(e);
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
                    _addExerciseToWorkout(newEx);
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

  void _saveWorkout() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Add at least one exercise with sets before saving.'),
        ),
      );
      return;
    }

    final name = _nameController.text.trim();

    // Decide if this is a planned or completed workout
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    final status = selected.isAfter(today)
        ? WorkoutStatus.planned
        : WorkoutStatus.completed;

    final session = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.isEmpty ? 'Workout' : name,
      date: _selectedDate,
      exercises: _items
          .where((we) => we.sets.isNotEmpty)
          .toList(),
      status: status,
    );

    widget.onSaveSession(session);

    setState(() {
      _items.clear();
      _nameController.clear();
      _selectedDate = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == WorkoutStatus.planned
              ? 'Planned workout saved.'
              : 'Workout saved.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Workout name + date
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Workout name',
                      hintText: 'e.g. Upper 1, Pull, Legs',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(dateStr),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Add exercise button
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
              child: _items.isEmpty
                  ? Center(
                      child: Text(
                        'No exercises yet.\nTap "Add exercise" to start.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final we = _items[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
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
                                          _removeExerciseFromWorkout(
                                              we),
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

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saveWorkout,
                icon: const Icon(Icons.save),
                label: const Text('Save workout'),
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
