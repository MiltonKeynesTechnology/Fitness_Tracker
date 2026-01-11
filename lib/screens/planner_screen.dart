// lib/screens/planner_screen.dart

import 'package:flutter/material.dart';

import '../models.dart';

class _CustomDayPlan {
  final String name;
  final List<Exercise> exercises;

  _CustomDayPlan({required this.name, required this.exercises});
}

enum _PlanMode {
  weeks,
  endDate,
  indefinite,
}

class PlannerScreen extends StatefulWidget {
  final List<WorkoutSession> existingSessions;
  final List<Exercise> allExercises;

  /// Called for each generated planned WorkoutSession.
  final void Function(WorkoutSession) onAddSession;

  /// Needed so we can REPLACE previously generated plan sessions (no stacking).
  final void Function(WorkoutSession) onDeleteSession;

  const PlannerScreen({
    super.key,
    required this.existingSessions,
    required this.allExercises,
    required this.onAddSession,
    required this.onDeleteSession,
  });

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  late DateTime _startDate;

  _PlanMode _mode = _PlanMode.weeks;
  int _weeks = 4;
  DateTime? _endDate;

  /// weekday -> template session id (from completed sessions)
  final Map<int, String?> _templateIds = {};

  /// weekday -> custom day plan (name + exercises)
  final Map<int, _CustomDayPlan?> _customPlans = {};

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _startDate = _nextMonday(now);

    for (int w = DateTime.monday; w <= DateTime.sunday; w++) {
      _templateIds[w] = null;
      _customPlans[w] = null;
    }

    // Prefill the editor from existing WEEKLY PLAN generated sessions in the first week.
    // (Only works after you start generating sessions with source == 'weekly_plan'.)
    _prefillFromExistingWeeklyPlan();
  }

  void _prefillFromExistingWeeklyPlan() {
    final start = _dateOnly(_startDate);
    final end = start.add(const Duration(days: 6));

    final planSessions = widget.existingSessions
        .where((s) =>
            s.status == WorkoutStatus.planned &&
            s.source == 'weekly_plan' &&
            !_dateOnly(s.date).isBefore(start) &&
            !_dateOnly(s.date).isAfter(end))
        .toList();

    if (planSessions.isEmpty) return;

    for (final s in planSessions) {
      final weekday = s.date.weekday;
      final exercises = s.exercises.map((we) => we.exercise).toList();

      // Treat as custom so it's directly editable (name + exercise list).
      _customPlans[weekday] = _CustomDayPlan(name: s.name, exercises: exercises);
      _templateIds[weekday] = null;
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
    // Templates should generally be completed workouts (stable + real history),
    // so we don't accidentally template off planned items.
    final list = widget.existingSessions
        .where((s) => s.status == WorkoutStatus.completed)
        .toList();

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

        // If using end-date mode, keep endDate >= startDate
        if (_mode == _PlanMode.endDate && _endDate != null) {
          if (_dateOnly(_endDate!).isBefore(_dateOnly(_startDate))) {
            _endDate = _startDate;
          }
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final initial = _endDate ?? _startDate.add(const Duration(days: 27));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day);
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
                            final selected = selectedIds.contains(ex.id);
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
                              subtitle: Text(muscleGroupLabel(ex.group)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(null),
                            child: const Text('Cancel'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () {
                              final chosen =
                                  all.where((e) => selectedIds.contains(e.id)).toList();
                              if (chosen.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
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
        _templateIds[weekday] = null; // custom overrides template
      });
    }
  }

  DateTime _effectiveEndDate() {
    final start = _dateOnly(_startDate);

    switch (_mode) {
      case _PlanMode.weeks:
        final days = (_weeks * 7) - 1;
        return start.add(Duration(days: days));
      case _PlanMode.endDate:
        return _dateOnly(_endDate ?? start.add(const Duration(days: 27)));
      case _PlanMode.indefinite:
        // We must generate *some* finite horizon (since sessions are stored as concrete dates).
        // v1 choice: generate 12 weeks ahead.
        return start.add(const Duration(days: (12 * 7) - 1));
    }
  }

  void _applyWeeklyPlan() {
    final hasAnyTemplate = _templateIds.values.any((id) => id != null);
    final hasAnyCustom = _customPlans.values.any((p) => p != null);

    if (!hasAnyTemplate && !hasAnyCustom) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set at least one day (template or custom).'),
        ),
      );
      return;
    }

    final templates = _templateOptions;
    final templateById = {for (final t in templates) t.id: t};

    final start = _dateOnly(_startDate);
    final end = _effectiveEndDate();
    if (_dateOnly(end).isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date.')),
      );
      return;
    }

    // 1) Remove existing plan-generated sessions in this range (REPLACE semantics).
    final toRemove = widget.existingSessions
        .where((s) =>
            s.status == WorkoutStatus.planned &&
            s.source == 'weekly_plan' &&
            !_dateOnly(s.date).isBefore(start) &&
            !_dateOnly(s.date).isAfter(end))
        .toList();

    for (final s in toRemove) {
      widget.onDeleteSession(s);
    }

    // 2) Generate new sessions.
    final totalDays = end.difference(start).inDays + 1;
    final List<WorkoutSession> newSessions = [];

    for (int offset = 0; offset < totalDays; offset++) {
      final date = start.add(Duration(days: offset));
      final weekday = date.weekday;

      final templateId = _templateIds[weekday];
      final custom = _customPlans[weekday];

      if (templateId == null && custom == null) continue; // rest day

      if (custom != null) {
        final copiedExercises = custom.exercises.map((ex) {
          return WorkoutExercise(
            id: '${date.millisecondsSinceEpoch}_${ex.id}',
            exercise: ex,
            sets: <ExerciseSet>[],
          );
        }).toList();

        newSessions.add(
          WorkoutSession(
            id: '${date.millisecondsSinceEpoch}_weekly_custom_$weekday',
            name: custom.name,
            date: date,
            exercises: copiedExercises,
            status: WorkoutStatus.planned,
            source: 'weekly_plan',
          ),
        );
        continue;
      }

      final template = templateById[templateId];
      if (template == null) {
        // Template was deleted/changed; treat as rest silently.
        continue;
      }

      final copiedExercises = template.exercises.map((we) {
        return WorkoutExercise(
          id: '${date.millisecondsSinceEpoch}_${we.id}',
          exercise: we.exercise,
          sets: <ExerciseSet>[],
        );
      }).toList();

      newSessions.add(
        WorkoutSession(
          id: '${date.millisecondsSinceEpoch}_weekly_${template.id}',
          name: template.name,
          date: date,
          exercises: copiedExercises,
          status: WorkoutStatus.planned,
          source: 'weekly_plan',
        ),
      );
    }

    if (newSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing generated (are all days set to rest?)'),
        ),
      );
      return;
    }

    for (final s in newSessions) {
      widget.onAddSession(s);
    }

    final removedCount = toRemove.length;
    final addedCount = newSessions.length;

    Navigator.of(context).pop({'removed': removedCount, 'added': addedCount});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templates = _templateOptions;

    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    final effectiveEnd = _effectiveEndDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your workout plan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Start date
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start date'),
                    subtitle: Text(fmt(_startDate)),
                    onTap: _pickStartDate,
                  ),
                ),
              ],
            ),

            // Plan mode
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Repeat', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),

                    RadioListTile<_PlanMode>(
                      contentPadding: EdgeInsets.zero,
                      value: _PlanMode.weeks,
                      groupValue: _mode,
                      onChanged: (v) => setState(() => _mode = v!),
                      title: const Text('For a number of weeks'),
                      subtitle: Row(
                        children: [
                          const Text('Weeks: '),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: _weeks,
                            items: [1, 2, 3, 4, 5, 6, 7, 8, 12]
                                .map((w) => DropdownMenuItem(
                                      value: w,
                                      child: Text('$w'),
                                    ))
                                .toList(),
                            onChanged: _mode == _PlanMode.weeks
                                ? (v) {
                                    if (v == null) return;
                                    setState(() => _weeks = v);
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),

                    RadioListTile<_PlanMode>(
                      contentPadding: EdgeInsets.zero,
                      value: _PlanMode.endDate,
                      groupValue: _mode,
                      onChanged: (v) => setState(() => _mode = v!),
                      title: const Text('Until an end date'),
                      subtitle: Row(
                        children: [
                          Text(_endDate == null ? 'Pick a date' : fmt(_endDate!)),
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: _mode == _PlanMode.endDate ? _pickEndDate : null,
                            icon: const Icon(Icons.date_range),
                            label: const Text('Choose'),
                          ),
                        ],
                      ),
                    ),

                    RadioListTile<_PlanMode>(
                      contentPadding: EdgeInsets.zero,
                      value: _PlanMode.indefinite,
                      groupValue: _mode,
                      onChanged: (v) => setState(() => _mode = v!),
                      title: const Text('Recurring indefinitely'),
                      subtitle: const Text('For now, this generates 12 weeks ahead.'),
                    ),

                    const Divider(),
                    Text(
                      'Will generate: ${fmt(_dateOnly(_startDate))} → ${fmt(_dateOnly(effectiveEnd))}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Set your weekly plan. Each day can be Rest, a Template from history, or a Custom day (name + exercises).',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: 7,
                itemBuilder: (context, index) {
                  final weekday = DateTime.monday + index;
                  final label = _weekdayLabel(weekday);

                  final selectedTemplateId = _templateIds[weekday];
                  final selectedTemplate = selectedTemplateId == null
                      ? null
                      : templates.cast<WorkoutSession?>().firstWhere(
                            (t) => t!.id == selectedTemplateId,
                            orElse: () => null,
                          );

                  final custom = _customPlans[weekday];

                  String sublabel;
                  if (custom != null) {
                    sublabel = 'Custom: ${custom.name} • ${custom.exercises.length} exercises';
                  } else if (selectedTemplate != null) {
                    sublabel =
                        'Template: ${selectedTemplate.name} • ${selectedTemplate.exercises.length} exercises';
                  } else {
                    sublabel = 'Rest day';
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    label,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<WorkoutSession?>(
                                    value: custom != null ? null : selectedTemplate,
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
                                        _templateIds[weekday] = v?.id;
                                        if (v != null) {
                                          _customPlans[weekday] = null;
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    Icons.tune,
                                    color: custom != null ? theme.colorScheme.primary : null,
                                  ),
                                  tooltip: 'Edit custom day for $label',
                                  onPressed: () => _editCustomPlanFor(weekday),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  tooltip: 'Clear day (set to rest)',
                                  onPressed: () {
                                    setState(() {
                                      _templateIds[weekday] = null;
                                      _customPlans[weekday] = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              sublabel,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _applyWeeklyPlan,
                icon: const Icon(Icons.save),
                label: const Text('Save & update schedule'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
