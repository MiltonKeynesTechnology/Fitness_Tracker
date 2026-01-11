// lib/screens/weekly_goals_screen.dart
import 'package:flutter/material.dart';
import '../models.dart';

class WeeklyGoalsScreen extends StatefulWidget {
  final WeeklyNutritionGoals weeklyGoals;
  /// Old single daily goal used as a fallback when a weekday has no override.
  final NutritionGoal? baseGoal;

  /// Called when the user taps Save.
  /// You get the new weekly goals and the chosen fallback/base goal.
  final void Function(WeeklyNutritionGoals weekly, NutritionGoal? base) onSave;

  const WeeklyGoalsScreen({
    super.key,
    required this.weeklyGoals,
    required this.baseGoal,
    required this.onSave,
  });

  @override
  State<WeeklyGoalsScreen> createState() => _WeeklyGoalsScreenState();
}

class _WeeklyGoalsScreenState extends State<WeeklyGoalsScreen> {
  late List<TextEditingController> _caloriesCtrls;
  late List<TextEditingController> _proteinCtrls;
  late List<TextEditingController> _carbsCtrls;
  late List<TextEditingController> _fatCtrls;
  late List<TextEditingController> _fiberCtrls;

  static const _weekdayLabels = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  NutritionGoal? _goalForWeekday(int weekday) {
    // weekday 1..7
    return widget.weeklyGoals.byWeekday[weekday] ?? widget.baseGoal;
  }

  @override
  void initState() {
    super.initState();

    _caloriesCtrls = List.generate(7, (_) => TextEditingController());
    _proteinCtrls = List.generate(7, (_) => TextEditingController());
    _carbsCtrls   = List.generate(7, (_) => TextEditingController());
    _fatCtrls     = List.generate(7, (_) => TextEditingController());
    _fiberCtrls   = List.generate(7, (_) => TextEditingController());

    // Pre-fill from weeklyGoals or fallback baseGoal
    for (var i = 0; i < 7; i++) {
      final weekday = i + 1;
      final g = _goalForWeekday(weekday);

      _caloriesCtrls[i].text = g?.calories?.toString() ?? '';
      _proteinCtrls[i].text =
          g?.protein == null ? '' : g!.protein!.toStringAsFixed(0);
      _carbsCtrls[i].text =
          g?.carbs == null ? '' : g!.carbs!.toStringAsFixed(0);
      _fatCtrls[i].text =
          g?.fat == null ? '' : g!.fat!.toStringAsFixed(0);
      _fiberCtrls[i].text =
          g?.fiber == null ? '' : g!.fiber!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    for (final c in [
      ..._caloriesCtrls,
      ..._proteinCtrls,
      ..._carbsCtrls,
      ..._fatCtrls,
      ..._fiberCtrls,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _parseDouble(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  int? _parseInt(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t.replaceAll(',', ''));
  }

  void _handleClearAll() {
    setState(() {
      for (var i = 0; i < 7; i++) {
        _caloriesCtrls[i].clear();
        _proteinCtrls[i].clear();
        _carbsCtrls[i].clear();
        _fatCtrls[i].clear();
        _fiberCtrls[i].clear();
      }
    });
  }

  void _handleSave() {
    final newMap = <int, NutritionGoal?>{};

    for (var i = 0; i < 7; i++) {
      final weekday = i + 1;

      final cals = _parseInt(_caloriesCtrls[i].text);
      final prot = _parseDouble(_proteinCtrls[i].text);
      final car  = _parseDouble(_carbsCtrls[i].text);
      final ft   = _parseDouble(_fatCtrls[i].text);
      final fib  = _parseDouble(_fiberCtrls[i].text);

      final allNull = cals == null &&
          prot == null &&
          car == null &&
          ft == null &&
          fib == null;

      if (allNull) {
        newMap[weekday] = null;
      } else {
        newMap[weekday] = NutritionGoal(
          calories: cals,
          protein: prot,
          carbs: car,
          fat: ft,
          fiber: fib,
        );
      }
    }

    final weekly = WeeklyNutritionGoals(byWeekday: newMap);

    // Fallback/base goal used by dashboard & other parts:
    // Prefer Monday if set, otherwise first non-null day.
    NutritionGoal? fallback = newMap[DateTime.monday];
    fallback ??= newMap.values
        .firstWhere((g) => g != null, orElse: () => null);

    widget.onSave(weekly, fallback);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly nutrition goals'),
        actions: [
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(Icons.delete_outline),
            onPressed: _handleClearAll,
          ),
          TextButton(
            onPressed: _handleSave,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 7,
        itemBuilder: (context, i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _weekdayLabels[i],
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _caloriesCtrls[i],
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: false),
                      decoration: const InputDecoration(
                        labelText: 'Calories (kcal)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _proteinCtrls[i],
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Protein (g)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _carbsCtrls[i],
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Carbs (g)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _fatCtrls[i],
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Fat (g)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _fiberCtrls[i],
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Fiber (g)',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
