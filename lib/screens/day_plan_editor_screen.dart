import 'package:flutter/material.dart';

import '../models.dart';

/// Return object from the day editor.
/// PlannerScreen can use this to update BOTH weeklyGoals + weeklyPlanExtras.
class DayPlanEditResult {
  final WeeklyNutritionGoals weeklyGoals;
  final WeeklyPlanExtras weeklyPlanExtras;

  DayPlanEditResult({
    required this.weeklyGoals,
    required this.weeklyPlanExtras,
  });
}

class DayPlanEditorScreen extends StatefulWidget {
  final int weekday; // DateTime.monday..DateTime.sunday

  /// Source-of-truth for daily macro goals used by Nutrition screen
  final WeeklyNutritionGoals weeklyGoals;

  /// All other “plan extras” (micros, meals, run, optional goal mirror)
  final WeeklyPlanExtras weeklyPlanExtras;

  /// Cookbook meals to pick from
  final List<CookbookMeal> cookbookMeals;

  /// OPTIONAL: show a workout summary + button that opens your existing workout editor flow
  final String? workoutSummary;
  final Future<void> Function()? onEditWorkout;

  const DayPlanEditorScreen({
    super.key,
    required this.weekday,
    required this.weeklyGoals,
    required this.weeklyPlanExtras,
    required this.cookbookMeals,
    this.workoutSummary,
    this.onEditWorkout,
  });

  @override
  State<DayPlanEditorScreen> createState() => _DayPlanEditorScreenState();
}

class _DayPlanEditorScreenState extends State<DayPlanEditorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Draft state
  NutritionGoal? _goal; // stored to WeeklyNutritionGoals + mirrored into extras
  late List<String> _microGoals;
  late Map<String, List<String>> _mealsByType; // MealType.name -> cookbook IDs
  RunPlan? _runPlan;

  // Controllers for macro inputs
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _fiberCtrl = TextEditingController();

  // Run UI draft
  RunTargetType _runTargetType = RunTargetType.time;
  final _runMinutesCtrl = TextEditingController();
  final _runDistanceCtrl = TextEditingController();
  final _runPaceCtrl = TextEditingController();
  final _runBpmCtrl = TextEditingController();
  final _runNotesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);

    // pull initial values from both stores
    _goal = widget.weeklyGoals.byWeekday[widget.weekday];

    final dayExtras = widget.weeklyPlanExtras.forWeekday(widget.weekday);
    _microGoals = List<String>.from(dayExtras.microGoals);
    _mealsByType = {
      ...dayExtras.mealsByType.map((k, v) => MapEntry(k, List<String>.from(v))),
    };
    _runPlan = dayExtras.runPlan;

    _hydrateMacroControllers(_goal);
    _hydrateRunControllers(_runPlan);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _fiberCtrl.dispose();

    _runMinutesCtrl.dispose();
    _runDistanceCtrl.dispose();
    _runPaceCtrl.dispose();
    _runBpmCtrl.dispose();
    _runNotesCtrl.dispose();

    super.dispose();
  }

  void _hydrateMacroControllers(NutritionGoal? g) {
    _kcalCtrl.text = g?.calories?.toString() ?? '';
    _proteinCtrl.text = g?.protein?.toString() ?? '';
    _carbsCtrl.text = g?.carbs?.toString() ?? '';
    _fatCtrl.text = g?.fat?.toString() ?? '';
    _fiberCtrl.text = g?.fiber?.toString() ?? '';
  }

  void _hydrateRunControllers(RunPlan? p) {
    if (p == null) return;

    _runTargetType = p.targetType;
    _runMinutesCtrl.text = p.minutes?.toString() ?? '';
    _runDistanceCtrl.text = p.distanceKm?.toString() ?? '';
    _runPaceCtrl.text = p.paceMinPerKm ?? '';
    _runBpmCtrl.text = p.targetBpm?.toString() ?? '';
    _runNotesCtrl.text = p.notes ?? '';
  }

  String _weekdayLabelLong(int weekday) {
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
        return 'Day';
    }
  }

  int? _toInt(String s) => int.tryParse(s.trim());
  double? _toDouble(String s) => double.tryParse(s.trim());

  NutritionGoal? _buildGoalFromInputs() {
    final kcal = _toInt(_kcalCtrl.text);
    final protein = _toDouble(_proteinCtrl.text);
    final carbs = _toDouble(_carbsCtrl.text);
    final fat = _toDouble(_fatCtrl.text);
    final fiber = _toDouble(_fiberCtrl.text);

    // If everything empty -> treat as no goal set
    final any = kcal != null || protein != null || carbs != null || fat != null || fiber != null;
    if (!any) return null;

    return NutritionGoal(
      calories: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
    );
  }

  RunPlan? _buildRunPlanFromInputs() {
    final notes = _runNotesCtrl.text.trim().isEmpty ? null : _runNotesCtrl.text.trim();

    switch (_runTargetType) {
      case RunTargetType.time:
        final m = _toInt(_runMinutesCtrl.text);
        if (m == null) return null;
        return RunPlan(targetType: RunTargetType.time, minutes: m, notes: notes);

      case RunTargetType.distance:
        final km = _toDouble(_runDistanceCtrl.text);
        if (km == null) return null;
        return RunPlan(targetType: RunTargetType.distance, distanceKm: km, notes: notes);

      case RunTargetType.pace:
        final pace = _runPaceCtrl.text.trim();
        if (pace.isEmpty) return null;
        return RunPlan(targetType: RunTargetType.pace, paceMinPerKm: pace, notes: notes);

      case RunTargetType.heartRate:
        final bpm = _toInt(_runBpmCtrl.text);
        if (bpm == null) return null;
        return RunPlan(targetType: RunTargetType.heartRate, targetBpm: bpm, notes: notes);
    }
  }

  Future<void> _saveAndClose() async {
    // Build drafts
    final newGoal = _buildGoalFromInputs();
    final newRunPlan = _buildRunPlanFromInputs();

    // 1) Update WeeklyNutritionGoals (source of truth for nutrition screen)
    final nextGoals = Map<int, NutritionGoal?>.from(widget.weeklyGoals.byWeekday);
    nextGoals[widget.weekday] = newGoal;
    final updatedWeeklyGoals = widget.weeklyGoals.copyWith(byWeekday: nextGoals);

    // 2) Update WeeklyPlanExtras for this weekday
    final oldDay = widget.weeklyPlanExtras.forWeekday(widget.weekday);
    final newDay = oldDay.copyWith(
      nutritionGoal: newGoal, // mirror for convenience (optional but nice)
      microGoals: List<String>.from(_microGoals),
      mealsByType: {
        ..._mealsByType.map((k, v) => MapEntry(k, List<String>.from(v))),
      },
      runPlan: newRunPlan,
    );

    final updatedExtras = widget.weeklyPlanExtras.copyWithDay(widget.weekday, newDay);

    if (!mounted) return;
    Navigator.of(context).pop(
      DayPlanEditResult(
        weeklyGoals: updatedWeeklyGoals,
        weeklyPlanExtras: updatedExtras,
      ),
    );
  }

  // ---------------------------
  // MICROS
  // ---------------------------

  Future<void> _addMicroGoal() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add micro goal'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'e.g. Fiber, Iron, Omega-3…',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    final v = result?.trim();
    if (v == null || v.isEmpty) return;

    setState(() {
      if (!_microGoals.contains(v)) _microGoals.add(v);
    });
  }

  void _removeMicro(String v) {
    setState(() => _microGoals.remove(v));
  }

  // ---------------------------
  // MEALS
  // ---------------------------

  List<CookbookMeal> _mealsOfType(MealType t) =>
      widget.cookbookMeals.where((m) => m.mealType == t).toList();

  String _cookbookTitleById(String id) {
    final m = widget.cookbookMeals.where((x) => x.id == id).toList();
    if (m.isEmpty) return id;
    return m.first.title;
  }

  void _addCookbookMeal(MealType type, String mealId) {
    final key = type.name;
    setState(() {
      final list = _mealsByType[key] ?? <String>[];
      if (!list.contains(mealId)) {
        _mealsByType[key] = [...list, mealId];
      }
    });
  }

  void _removeCookbookMeal(MealType type, String mealId) {
    final key = type.name;
    setState(() {
      final list = _mealsByType[key] ?? <String>[];
      _mealsByType[key] = list.where((x) => x != mealId).toList();
    });
  }

  // ---------------------------
  // SUGGESTIONS
  // ---------------------------

  List<String> _buildSuggestions() {
    final g = _buildGoalFromInputs();
    final suggestions = <String>[];

    if (g == null) {
      suggestions.add('Set a macro goal (even rough) to make the day “trackable”.');
    } else {
      if ((g.protein ?? 0) < 120) {
        suggestions.add('Protein looks low — consider adding a high-protein meal/snack.');
      }
      if ((g.fiber ?? 0) < 25) {
        suggestions.add('Fiber goal is low — add veggies/berries/whole grains or a fiber-focused meal.');
      }
      if ((g.calories ?? 0) > 0 && (g.calories ?? 0) < 1600) {
        suggestions.add('Calories are quite low — make sure this matches your goal and training load.');
      }
    }

    if (_microGoals.isEmpty) {
      suggestions.add('Add 1–2 micro goals (e.g. Fiber, Iron, Omega-3) to shape food choices.');
    }

    final totalPlannedMeals = _mealsByType.values.fold<int>(0, (s, v) => s + v.length);
    if (totalPlannedMeals == 0) {
      suggestions.add('Pick at least one cookbook meal — it makes the day easier to execute.');
    }

    final rp = _buildRunPlanFromInputs();
    if (rp == null) {
      suggestions.add('No run planned — add a simple target (time / pace / HR) if you’re running this week.');
    } else {
      suggestions.add('Run is set — keep it easy if today is also a heavy leg day.');
    }

    // Workout suggestion (basic)
    if ((widget.workoutSummary ?? '').trim().isEmpty) {
      suggestions.add('No workout set — either plan a session or mark as rest.');
    }

    return suggestions;
  }

  @override
  Widget build(BuildContext context) {
    final title = '${_weekdayLabelLong(widget.weekday)} plan';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.save),
            onPressed: _saveAndClose,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Workout'),
            Tab(text: 'Macros'),
            Tab(text: 'Micros'),
            Tab(text: 'Meals'),
            Tab(text: 'Run'),
            Tab(text: 'Suggestions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _workoutTab(context),
          _macrosTab(context),
          _microsTab(context),
          _mealsTab(context),
          _runTab(context),
          _suggestionsTab(context),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: FilledButton.icon(
            onPressed: _saveAndClose,
            icon: const Icon(Icons.save),
            label: const Text('Save day'),
          ),
        ),
      ),
    );
  }

  Widget _workoutTab(BuildContext context) {
    final theme = Theme.of(context);
    final summary = (widget.workoutSummary ?? '').trim();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Workout',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Edit the exercises for this day. This links to your existing workout “Custom” editor.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            title: Text(summary.isEmpty ? 'No workout set' : 'Planned workout'),
            subtitle: Text(summary.isEmpty ? 'Rest day / no exercises' : summary),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onEditWorkout == null
                ? null
                : () async {
                    await widget.onEditWorkout!.call();
                    // PlannerScreen can rebuild the summary when returning
                    if (mounted) setState(() {});
                  },
          ),
        ),
        const SizedBox(height: 10),
        if (widget.onEditWorkout == null)
          Text(
            'Hook needed: pass onEditWorkout + workoutSummary from PlannerScreen so this opens your workout editor.',
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _macrosTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Daily macro targets'),
        const SizedBox(height: 12),
        _numField(_kcalCtrl, label: 'Calories (kcal)', isInt: true),
        const SizedBox(height: 10),
        _numField(_proteinCtrl, label: 'Protein (g)'),
        const SizedBox(height: 10),
        _numField(_carbsCtrl, label: 'Carbs (g)'),
        const SizedBox(height: 10),
        _numField(_fatCtrl, label: 'Fat (g)'),
        const SizedBox(height: 10),
        _numField(_fiberCtrl, label: 'Fiber (g)'),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _kcalCtrl.clear();
              _proteinCtrl.clear();
              _carbsCtrl.clear();
              _fatCtrl.clear();
              _fiberCtrl.clear();
            });
          },
          icon: const Icon(Icons.clear),
          label: const Text('Clear macro goal for this day'),
        ),
        const SizedBox(height: 8),
        const Text(
          'These values write into WeeklyNutritionGoals (used by the Nutrition screen).',
        ),
      ],
    );
  }

  Widget _microsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(child: Text('Micro goals')),
            FilledButton.icon(
              onPressed: _addMicroGoal,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_microGoals.isEmpty)
          const Text('No micro goals yet. Add a couple like “Iron”, “Omega-3”, “Fiber”.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _microGoals
                .map(
                  (m) => InputChip(
                    label: Text(m),
                    onDeleted: () => _removeMicro(m),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 12),
        const Text('These are stored in WeeklyPlanExtras → microGoals.'),
      ],
    );
  }

  Widget _mealsTab(BuildContext context) {
    final types = MealType.values;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Plan meals from your cookbook'),
        const SizedBox(height: 12),

        ...types.map((t) {
          final key = t.name;
          final plannedIds = _mealsByType[key] ?? <String>[];
          final available = _mealsOfType(t);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mealTypeLabel(t), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),

                  // Picker
                  DropdownButtonFormField<String>(
                    value: null,
                    decoration: const InputDecoration(
                      labelText: 'Add cookbook meal',
                      border: OutlineInputBorder(),
                    ),
                    items: available
                        .map(
                          (m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(m.title),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id == null) return;
                      _addCookbookMeal(t, id);
                    },
                  ),

                  const SizedBox(height: 10),

                  if (plannedIds.isEmpty)
                    const Text('None planned.')
                  else
                    Column(
                      children: plannedIds.map((id) {
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(_cookbookTitleById(id)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeCookbookMeal(t, id),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          );
        }).toList(),

        const SizedBox(height: 8),
        const Text('Stored in WeeklyPlanExtras → mealsByType (MealType.name → [cookbook IDs]).'),
      ],
    );
  }

  Widget _runTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Run plan'),
        const SizedBox(height: 12),

        DropdownButtonFormField<RunTargetType>(
          value: _runTargetType,
          decoration: const InputDecoration(
            labelText: 'Target type',
            border: OutlineInputBorder(),
          ),
          items: RunTargetType.values
              .map((t) => DropdownMenuItem(value: t, child: Text(runTargetTypeLabel(t))))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _runTargetType = v);
          },
        ),

        const SizedBox(height: 12),

        if (_runTargetType == RunTargetType.time)
          _numField(_runMinutesCtrl, label: 'Minutes', isInt: true)
        else if (_runTargetType == RunTargetType.distance)
          _numField(_runDistanceCtrl, label: 'Distance (km)')
        else if (_runTargetType == RunTargetType.pace)
          TextField(
            controller: _runPaceCtrl,
            decoration: const InputDecoration(
              labelText: 'Pace (min/km) e.g. 5:30',
              border: OutlineInputBorder(),
            ),
          )
        else if (_runTargetType == RunTargetType.heartRate)
          _numField(_runBpmCtrl, label: 'Target HR (bpm)', isInt: true),

        const SizedBox(height: 12),

        TextField(
          controller: _runNotesCtrl,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _runPlan = _buildRunPlanFromInputs();
                });
              },
              icon: const Icon(Icons.check),
              label: const Text('Apply'),
            ),
            const SizedBox(width: 10),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _runPlan = null;
                  _runMinutesCtrl.clear();
                  _runDistanceCtrl.clear();
                  _runPaceCtrl.clear();
                  _runBpmCtrl.clear();
                  _runNotesCtrl.clear();
                  _runTargetType = RunTargetType.time;
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
            ),
          ],
        ),

        const SizedBox(height: 12),
        Text(
          _buildRunPlanFromInputs() == null
              ? 'No run planned.'
              : 'Run planned: ${runTargetTypeLabel(_runTargetType)}',
        ),

        const SizedBox(height: 8),
        const Text('Stored in WeeklyPlanExtras → runPlan.'),
      ],
    );
  }

  Widget _suggestionsTab(BuildContext context) {
    final suggestions = _buildSuggestions();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Suggestions for this day'),
        const SizedBox(height: 12),
        if (suggestions.isEmpty)
          const Text('No suggestions — looks good!')
        else
          ...suggestions.map(
            (s) => Card(
              child: ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: Text(s),
              ),
            ),
          ),
      ],
    );
  }

  Widget _numField(
    TextEditingController controller, {
    required String label,
    bool isInt = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        hintText: isInt ? 'e.g. 2200' : 'e.g. 150',
      ),
    );
  }
}
