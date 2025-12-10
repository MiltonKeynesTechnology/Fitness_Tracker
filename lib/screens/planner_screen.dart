// lib/screens/planner_screen.dart

import 'package:flutter/material.dart';

import '../models.dart';

class _CustomDayPlan {
  final String name;
  final List<Exercise> exercises;

  _CustomDayPlan({required this.name, required this.exercises});
}

class PlannerScreen extends StatefulWidget {
  final List<WorkoutSession> existingSessions;
  final List<Exercise> allExercises;

  /// Called for each generated planned WorkoutSession.
  final void Function(WorkoutSession) onAddSession;

  const PlannerScreen({
    super.key,
    required this.existingSessions,
    required this.allExercises,
    required this.onAddSession,
  });

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  late DateTime _startDate;
  int _weeks = 4;

  /// weekday -> template session (from existing sessions)
  final Map<int, WorkoutSession?> _templates = {};

  /// weekday -> custom day plan (name + exercises)
  final Map<int, _CustomDayPlan?> _customPlans = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = _nextMonday(now);

    for (int w = DateTime.monday; w <= DateTime.sunday; w++) {
      _templates[w] = null;
      _customPlans[w] = null;
    }
  }

  DateTime _nextMonday(DateTime from) {
    final int weekday = from.weekday; // 1..7
    final int delta = (8 - weekday) % 7; // days until next Monday
    if (delta == 0) {
      return DateTime(from.year, from.month, from.day);
    }
    final d = from.add(Duration(days: delta));
    return DateTime(d.year, d.month, d.day);
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  List<WorkoutSession> get _templateOptions {
    final list = List<WorkoutSession>.from(widget.existingSessions);
    // If you only want completed sessions as templates, uncomment:
    // list.retainWhere((s) => s.status == WorkoutStatus.completed);
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _editCustomPlanFor(int weekday) async {
    final existing = _customPlans[weekday];
    final label = _weekdayLabel(weekday);

    String initialName = existing?.name ?? label;
    final all = widget.allExercises;
    final initialSelectedIds =
        existing?.exercises.map((e) => e.id).toSet() ?? <String>{};

    final result = await showModalBottomSheet<_CustomDayPlan>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final nameController = TextEditingController(text: initialName);
        Set<String> selectedIds = Set.of(initialSelectedIds);

        return DraggableScrollableSheet(
          expand: false,
          builder: (_, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Custom day – $label',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Day name',
                          hintText: 'e.g. Upper 1, Lower heavy',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: all.length,
                          itemBuilder: (context, index) {
                            final ex = all[index];
                            final selected =
                                selectedIds.contains(ex.id);
                            return CheckboxListTile(
                              value: selected,
                              onChanged: (v) {
                                setModalState(() {
                                  if (v == true) {
                                    selectedIds.add(ex.id);
                                  } else {
                                    selectedIds.remove(ex.id);
                                  }
                                });
                              },
                              title: Text(ex.name),
                              subtitle: Text(
                                muscleGroupLabel(ex.group),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(null);
                            },
                            child: const Text('Cancel'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () {
                              final chosen = all
                                  .where((e) =>
                                      selectedIds.contains(e.id))
                                  .toList();
                              if (chosen.isEmpty) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Pick at least one exercise for this custom day.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final name = nameController.text.trim().isEmpty
                                  ? label
                                  : nameController.text.trim();
                              Navigator.of(context).pop(
                                _CustomDayPlan(
                                  name: name,
                                  exercises: chosen,
                                ),
                              );
                            },
                            child: const Text('Save day'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _customPlans[weekday] = result;
      });
    }
  }

  void _generatePlan() {
    final hasAnyTemplate =
        _templates.values.any((t) => t != null);
    final hasAnyCustom =
        _customPlans.values.any((p) => p != null);

    if (!hasAnyTemplate && !hasAnyCustom) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Select at least one template or build a custom day.'),
        ),
      );
      return;
    }

    final totalDays = _weeks * 7;
    final List<WorkoutSession> newSessions = [];

    for (int offset = 0; offset < totalDays; offset++) {
      final date = _startDate.add(Duration(days: offset));
      final weekday = date.weekday; // 1..7

      final template = _templates[weekday];
      final custom = _customPlans[weekday];

      if (template == null && custom == null) {
        continue; // rest day
      }

      if (template != null) {
        // Copy template: same name & exercises, but no sets, planned status
        final copiedExercises = template.exercises.map((we) {
          return WorkoutExercise(
            id: '${date.millisecondsSinceEpoch}_${we.id}',
            exercise: we.exercise,
            sets: <ExerciseSet>[],
          );
        }).toList();

        final session = WorkoutSession(
          id: '${date.millisecondsSinceEpoch}_${template.id}',
          name: template.name,
          date: date,
          exercises: copiedExercises,
          status: WorkoutStatus.planned,
        );

        newSessions.add(session);
      } else if (custom != null) {
        final copiedExercises = custom.exercises.map((ex) {
          return WorkoutExercise(
            id: '${date.millisecondsSinceEpoch}_${ex.id}',
            exercise: ex,
            sets: <ExerciseSet>[],
          );
        }).toList();

        final session = WorkoutSession(
          id: '${date.millisecondsSinceEpoch}_custom_$weekday',
          name: custom.name,
          date: date,
          exercises: copiedExercises,
          status: WorkoutStatus.planned,
        );

        newSessions.add(session);
      }
    }

    if (newSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No workouts generated. Check your templates/custom days.'),
        ),
      );
      return;
    }

    for (final s in newSessions) {
      widget.onAddSession(s);
    }

    Navigator.of(context).pop(newSessions.length);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templates = _templateOptions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan weeks'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Start date + weeks
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start date'),
                    subtitle: Text(
                      '${_startDate.day.toString().padLeft(2, '0')}/'
                      '${_startDate.month.toString().padLeft(2, '0')}/'
                      '${_startDate.year}',
                    ),
                    onTap: _pickStartDate,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Weeks',
                    ),
                    value: _weeks,
                    items: [1, 2, 3, 4, 5, 6, 7, 8]
                        .map((w) => DropdownMenuItem(
                              value: w,
                              child: Text('$w'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _weeks = v;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'For each weekday, you can:\n'
              '• Pick a template workout from your history\n'
              '• OR build a custom day (name + exercises)\n'
              'Rest days are left with both blank.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: 7,
                itemBuilder: (context, index) {
                  final weekday = DateTime.monday + index; // 1..7
                  final label = _weekdayLabel(weekday);
                  final selectedTemplate = _templates[weekday];
                  final custom = _customPlans[weekday];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: Text(
                                label,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<WorkoutSession?>(
                                value: selectedTemplate,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Template / Rest',
                                ),
                                items: [
                                  const DropdownMenuItem<WorkoutSession?>(
                                    value: null,
                                    child: Text('Rest day / no template'),
                                  ),
                                  ...templates.map(
                                    (s) => DropdownMenuItem<WorkoutSession?>(
                                      value: s,
                                      child: Text(s.name),
                                    ),
                                  ),
                                ],
                                onChanged: (v) {
                                  setState(() {
                                    _templates[weekday] = v;
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.edit_calendar,
                                color: custom != null
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                              tooltip: 'Build custom day for $label',
                              onPressed: () => _editCustomPlanFor(weekday),
                            ),
                          ],
                        ),
                        if (custom != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 98,
                              top: 2,
                              bottom: 4,
                            ),
                            child: Text(
                              'Custom: ${custom.name} • ${custom.exercises.length} exercises',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _generatePlan,
                icon: const Icon(Icons.check),
                label: const Text('Generate plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
