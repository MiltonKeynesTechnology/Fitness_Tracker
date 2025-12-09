// lib/screens/exercises_screen.dart

import 'package:flutter/material.dart';

import '../models.dart';

class ExercisesScreen extends StatelessWidget {
  final List<Exercise> exercises;
  final List<WorkoutSession> sessions;
  final void Function(Exercise) onAddExercise;
  final void Function(Exercise) onUpdateExercise;

  const ExercisesScreen({
    super.key,
    required this.exercises,
    required this.sessions,
    required this.onAddExercise,
    required this.onUpdateExercise,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = List<Exercise>.from(exercises)
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<Exercise>(
            MaterialPageRoute(
              builder: (_) => ExerciseDetailScreen(
                isNew: true,
                initial: Exercise(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: '',
                  region: BodyRegion.upper,
                  group: MuscleGroup.midChest,
                  secondary: const [],
                  subGroup: null,
                  goalWeight: null,
                  goalReps: null,
                  manualPr: null,
                ),
              ),
            ),
          );

          if (created != null) {
            onAddExercise(created);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add exercise'),
      ),
      body: sorted.isEmpty
          ? const Center(
              child: Text('No exercises yet. Tap "+" to add one.'),
            )
          : ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final e = sorted[index];

                final primaryLabel = muscleGroupLabel(e.group);
                final secondaryLabels = e.secondary
                    .map(muscleGroupLabel)
                    .toList();

                String subtitle = bodyRegionLabel(e.region);
                subtitle += ' • $primaryLabel';
                if (secondaryLabels.isNotEmpty) {
                  subtitle += ' (+' + secondaryLabels.join(', ') + ')';
                }
                if (e.subGroup != null && e.subGroup!.trim().isNotEmpty) {
                  subtitle += ' • ${e.subGroup}';
                }

                return ListTile(
                  title: Text(e.name),
                  subtitle: Text(subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final updated =
                        await Navigator.of(context).push<Exercise>(
                      MaterialPageRoute(
                        builder: (_) => ExerciseDetailScreen(
                          isNew: false,
                          initial: e,
                        ),
                      ),
                    );

                    if (updated != null) {
                      onUpdateExercise(updated);
                    }
                  },
                );
              },
            ),
    );
  }
}

/// Screen to create or edit a single exercise.
class ExerciseDetailScreen extends StatefulWidget {
  final bool isNew;
  final Exercise initial;

  const ExerciseDetailScreen({
    super.key,
    required this.isNew,
    required this.initial,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _subGroupController;
  late TextEditingController _goalWeightController;
  late TextEditingController _goalRepsController;
  late TextEditingController _manualPrController;

  late BodyRegion _region;
  late MuscleGroup _primary;
  late Set<MuscleGroup> _secondary; // use a Set for easy toggling

  @override
  void initState() {
    super.initState();
    final ex = widget.initial;
    _nameController = TextEditingController(text: ex.name);
    _subGroupController =
        TextEditingController(text: ex.subGroup ?? '');
    _goalWeightController = TextEditingController(
        text: ex.goalWeight?.toString() ?? '');
    _goalRepsController =
        TextEditingController(text: ex.goalReps?.toString() ?? '');
    _manualPrController =
        TextEditingController(text: ex.manualPr?.toString() ?? '');

    _region = ex.region;
    _primary = ex.group;
    _secondary = ex.secondary.toSet();
    // Ensure primary is not duplicated in secondary
    _secondary.remove(_primary);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subGroupController.dispose();
    _goalWeightController.dispose();
    _goalRepsController.dispose();
    _manualPrController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty.')),
      );
      return;
    }

    final sub = _subGroupController.text.trim();
    final goalWeight =
        double.tryParse(_goalWeightController.text.trim());
    final goalReps =
        int.tryParse(_goalRepsController.text.trim());
    final manualPr =
        double.tryParse(_manualPrController.text.trim());

    final cleanedSecondary = _secondary.toSet()..remove(_primary);

    final updated = widget.initial.copyWith(
      name: name,
      region: _region,
      group: _primary,
      secondary: cleanedSecondary.toList(),
      subGroup: sub.isEmpty ? null : sub,
      goalWeight: goalWeight,
      goalReps: goalReps,
      manualPr: manualPr,
    );

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New exercise' : 'Edit exercise'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check),
            tooltip: 'Save',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Lat Pulldown',
              ),
            ),
            const SizedBox(height: 12),

            // Region
            DropdownButtonFormField<BodyRegion>(
              value: _region,
              decoration: const InputDecoration(
                labelText: 'Body region',
              ),
              items: BodyRegion.values.map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text(bodyRegionLabel(r)),
                );
              }).toList(),
              onChanged: (r) {
                if (r != null) {
                  setState(() => _region = r);
                }
              },
            ),
            const SizedBox(height: 12),

            // Primary muscle
            DropdownButtonFormField<MuscleGroup>(
              value: _primary,
              decoration: const InputDecoration(
                labelText: 'Primary muscle',
              ),
              items: MuscleGroup.values.map((g) {
                return DropdownMenuItem(
                  value: g,
                  child: Text(muscleGroupLabel(g)),
                );
              }).toList(),
              onChanged: (g) {
                if (g != null) {
                  setState(() {
                    _primary = g;
                    // A primary muscle cannot also be secondary
                    _secondary.remove(g);
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            Text(
              'Secondary muscles (optional)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // Multi-select chips for secondary muscles
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: MuscleGroup.values.map((g) {
                final isPrimary = g == _primary;
                final isSelected = _secondary.contains(g);

                return FilterChip(
                  label: Text(
                    isPrimary
                        ? '${muscleGroupLabel(g)} (primary)'
                        : muscleGroupLabel(g),
                  ),
                  selected: isSelected,
                  onSelected: isPrimary
                      ? null // can't toggle primary here
                      : (selected) {
                          setState(() {
                            if (selected) {
                              _secondary.add(g);
                            } else {
                              _secondary.remove(g);
                            }
                          });
                        },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _subGroupController,
              decoration: const InputDecoration(
                labelText: 'Notes / variation (optional)',
                hintText: 'e.g. Cable, neutral grip, incline',
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Goals & PR (optional)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _goalWeightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Goal weight (kg)',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _goalRepsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Goal reps',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _manualPrController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Manual PR weight (kg)',
                hintText: 'If you want to set an existing PR',
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
