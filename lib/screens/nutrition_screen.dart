// lib/screens/nutrition_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'log_meal_screen.dart';

import '../models.dart';

class _TempMealItem {
  String name;
  int? calories;
  double? protein;
  double? carbs;
  double? fat;
  double? fiber;

  _TempMealItem({
    required this.name,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
  });
}

class NutritionScreen extends StatelessWidget {
  final List<MealEntry> meals;
  final List<SupplementEntry> supplements;

  final void Function(MealEntry) onAddMeal;
  final void Function(MealEntry) onUpdateMeal;
  final void Function(MealEntry) onDeleteMeal;

  final void Function(SupplementEntry) onAddSupplement;
  final void Function(SupplementEntry) onUpdateSupplement;
  final void Function(SupplementEntry) onDeleteSupplement;

  final NutritionGoal? nutritionGoal;
  final void Function(NutritionGoal?) onUpdateGoal;

  const NutritionScreen({
    super.key,
    required this.meals,
    required this.supplements,
    required this.onAddMeal,
    required this.onUpdateMeal,
    required this.onDeleteMeal,
    required this.onAddSupplement,
    required this.onUpdateSupplement,
    required this.onDeleteSupplement,
    required this.nutritionGoal,
    required this.onUpdateGoal,
  });

  String _formatDateTime(DateTime dt) {
    final date =
        '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:' 
        '${dt.minute.toString().padLeft(2, '0')}';
    return '$date • $time';
  }

  Future<_TempMealItem?> _showAddMealItemDialog(
    BuildContext context,
  ) async {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();
    final fiberController = TextEditingController();

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

    return showDialog<_TempMealItem>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add food item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item name',
                  hintText: 'e.g. 150g chicken breast',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: caloriesController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                decoration: const InputDecoration(
                  labelText: 'Calories (kcal)',
                  hintText: 'e.g. 250',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: proteinController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Protein (g)',
                        hintText: 'e.g. 30',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: carbsController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Carbs (g)',
                        hintText: 'e.g. 0',
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
                      controller: fatController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Fat (g)',
                        hintText: 'e.g. 5',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fiberController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Fiber (g)',
                        hintText: 'e.g. 0',
                      ),
                    ),
                  ),
                ],
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
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter an item name.'),
                  ),
                );
                return;
              }
              final cals = _parseInt(caloriesController.text);
              final prot = _parseDouble(proteinController.text);
              final car = _parseDouble(carbsController.text);
              final ft = _parseDouble(fatController.text);
              final fib = _parseDouble(fiberController.text);

              Navigator.of(ctx).pop(
                _TempMealItem(
                  name: name,
                  calories: cals,
                  protein: prot,
                  carbs: car,
                  fat: ft,
                  fiber: fib,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSupplementDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final doseController = TextEditingController();
    final unitController = TextEditingController(text: 'g');
    final notesController = TextEditingController();

    SupplementCategory selectedCategory = SupplementCategory.other;

    double? _parseDouble(String text) {
      final t = text.trim();
      if (t.isEmpty) return null;
      return double.tryParse(t.replaceAll(',', '.'));
    }

    final result = await showDialog<SupplementEntry>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text('Log a supplement'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Supplement',
                      hintText: 'e.g. Whey, Creatine, Vitamin D3',
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SupplementCategory>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                    ),
                    items: SupplementCategory.values.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(supplementCategoryLabel(c)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setStateDialog(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: doseController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Dose',
                            hintText: 'e.g. 5',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: unitController,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            hintText: 'g, mg, caps',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'e.g. pre-workout, before bed...',
                    ),
                    maxLines: 2,
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
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a name.'),
                      ),
                    );
                    return;
                  }
                  final dose = _parseDouble(doseController.text);
                  final unit = unitController.text.trim().isEmpty
                      ? null
                      : unitController.text.trim();
                  final notes = notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim();

                  final entry = SupplementEntry(
                    id: DateTime.now()
                        .millisecondsSinceEpoch
                        .toString(),
                    dateTime: DateTime.now(),
                    name: name,
                    category: selectedCategory,
                    dose: dose,
                    unit: unit,
                    notes: notes,
                  );
                  Navigator.of(ctx).pop(entry);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result == null) return;
    onAddSupplement(result);
  }

  Future<void> _showEditGoalDialog(BuildContext context) async {
    final current = nutritionGoal;

    final caloriesController = TextEditingController(
      text: current?.calories?.toString() ?? '',
    );
    final proteinController = TextEditingController(
      text: current?.protein?.toStringAsFixed(0) ?? '',
    );
    final carbsController = TextEditingController(
      text: current?.carbs?.toStringAsFixed(0) ?? '',
    );
    final fatController = TextEditingController(
      text: current?.fat?.toStringAsFixed(0) ?? '',
    );
    final fiberController = TextEditingController(
      text: current?.fiber?.toStringAsFixed(0) ?? '',
    );

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

    final result = await showDialog<NutritionGoal?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set daily nutrition goals'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: caloriesController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                decoration: const InputDecoration(
                  labelText: 'Calories (kcal/day)',
                  hintText: 'e.g. 2400',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: proteinController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Protein (g/day)',
                  hintText: 'e.g. 160',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: carbsController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Carbs (g/day)',
                  hintText: 'e.g. 220',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: fatController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Fat (g/day)',
                  hintText: 'e.g. 70',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: fiberController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Fiber (g/day)',
                  hintText: 'e.g. 25',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(NutritionGoal()),
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () {
              final cals = _parseInt(caloriesController.text);
              final prot = _parseDouble(proteinController.text);
              final car = _parseDouble(carbsController.text);
              final ft = _parseDouble(fatController.text);
              final fib = _parseDouble(fiberController.text);

              Navigator.of(ctx).pop(
                NutritionGoal(
                  calories: cals,
                  protein: prot,
                  carbs: car,
                  fat: ft,
                  fiber: fib,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;
    if (result.calories == null &&
        result.protein == null &&
        result.carbs == null &&
        result.fat == null &&
        result.fiber == null) {
      onUpdateGoal(null);
    } else {
      onUpdateGoal(result);
    }
  }

  Future<void> _showEditMealDialog(BuildContext context, MealEntry meal) async {
    // we now edit via LogMealScreen, not the simple dialog
    final updated = await Navigator.of(context).push<MealEntry>(
      MaterialPageRoute(
        builder: (_) => LogMealScreen(initialMeal: meal),
      ),
    );

    if (updated == null) return;

    onUpdateMeal(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Meal updated.')),
    );
  }

  Future<void> _showEditSupplementDialog(
    BuildContext context,
    SupplementEntry supp,
  ) async {
    final nameController = TextEditingController(text: supp.name);
    final doseController = TextEditingController(
      text: supp.dose?.toString() ?? '',
    );
    final unitController = TextEditingController(text: supp.unit ?? '');
    final notesController = TextEditingController(text: supp.notes ?? '');

    SupplementCategory selectedCategory = supp.category;

    double? _parseDouble(String text) {
      final t = text.trim();
      if (t.isEmpty) return null;
      return double.tryParse(t.replaceAll(',', '.'));
    }

    final updated = await showDialog<SupplementEntry>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text('Edit supplement'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Supplement',
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SupplementCategory>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                    ),
                    items: SupplementCategory.values.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(supplementCategoryLabel(c)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setStateDialog(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: doseController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Dose',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: unitController,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                    ),
                    maxLines: 2,
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
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a name.'),
                      ),
                    );
                    return;
                  }

                  final dose = _parseDouble(doseController.text);
                  final unit = unitController.text.trim().isEmpty
                      ? null
                      : unitController.text.trim();
                  final notes = notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim();

                  Navigator.of(ctx).pop(
                    SupplementEntry(
                      id: supp.id,
                      dateTime: supp.dateTime,
                      name: name,
                      category: selectedCategory,
                      dose: dose,
                      unit: unit,
                      notes: notes,
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (updated == null) return;

    onUpdateSupplement(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Supplement updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    bool _sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    final todaysMeals = meals.where((m) => _sameDay(m.dateTime, now));
    final todaysSupplements =
        supplements.where((s) => _sameDay(s.dateTime, now)).toList();

    final int totalCalories = todaysMeals.fold<int>(
      0,
      (sum, m) => sum + (m.calories ?? 0),
    );

    final double totalProtein = todaysMeals.fold<double>(
      0,
      (sum, m) => sum + (m.protein ?? 0),
    );

    final double totalCarbs = todaysMeals.fold<double>(
      0,
      (sum, m) => sum + (m.carbs ?? 0),
    );

    final double totalFat = todaysMeals.fold<double>(
      0,
      (sum, m) => sum + (m.fat ?? 0),
    );

    final double totalFiber = todaysMeals.fold<double>(
      0,
      (sum, m) => sum + (m.fiber ?? 0),
    );

    final NutritionGoal? goal = nutritionGoal;

    final proteinColor = Colors.blueAccent;
    final carbsColor = Colors.orangeAccent;
    final fatColor = Colors.pinkAccent;
    final fiberColor = Colors.greenAccent;

    final macroValues = [
      totalProtein,
      totalCarbs,
      totalFat,
      totalFiber,
    ];
    final macroColors = [
      proteinColor,
      carbsColor,
      fatColor,
      fiberColor,
    ];
    final macroTotal =
      macroValues.fold<double>(0, (sum, v) => sum + v);

    // --- Helpers for new dashboard UI ---

        // --- NEW: weekly calories aggregation ---
    final todayDate = DateTime(now.year, now.month, now.day);
    final weekDays = List.generate(
      7,
      (i) => todayDate.subtract(Duration(days: 6 - i)), // oldest -> today
    );

    final Map<DateTime, int> caloriesPerDay = {
      for (final d in weekDays) d: 0,
    };

    for (final meal in meals) {
      final d = DateTime(
        meal.dateTime.year,
        meal.dateTime.month,
        meal.dateTime.day,
      );
      if (!caloriesPerDay.containsKey(d)) continue;
      caloriesPerDay[d] = caloriesPerDay[d]! + (meal.calories ?? 0);
    }

    final maxDayCalories = caloriesPerDay.values.fold<int>(
      0,
      (max, v) => v > max ? v : max,
    );

    final double maxForScale = ([
      maxDayCalories.toDouble(),
      (goal?.calories?.toDouble() ?? 0),
      1.0,
    ]..sort())
        .last; // pick the largest of (maxDay, goal, 1)

    const double _macroChartSize = 110.0; // use same size for ring + pie

    Widget buildCalorieRing() {
      final goalCals = goal?.calories;
      double? rawProgress;
      if (goalCals != null && goalCals > 0) {
        rawProgress = totalCalories / goalCals;
      }

      final clamped =
          rawProgress != null ? rawProgress.clamp(0.0, 1.0) : 0.0;
      final overGoal = rawProgress != null && rawProgress > 1.0;

      final colorScheme = theme.colorScheme;

      // 🔹 Helper to pick a colour based on progress (0–1):
      Color _calorieColor(double p) {
        p = p.clamp(0.0, 1.0);
        const low = Colors.blueAccent;
        const mid = Colors.amberAccent;
        const high = Colors.greenAccent;

        if (p <= 0.5) {
          final t = p / 0.5; // 0 → 0.5  = blue → yellow
          return Color.lerp(low, mid, t)!;
        } else {
          final t = (p - 0.5) / 0.5; // 0.5 → 1 = yellow → green
          return Color.lerp(mid, high, t)!;
        }
      }

      final ringColor = overGoal
          ? colorScheme.error
          : _calorieColor(clamped.toDouble());

      return SizedBox(
        width: _macroChartSize,
        height: _macroChartSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: goalCals == null ? 0 : clamped,
                strokeWidth: _macroChartSize * 0.18,
                valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                backgroundColor: colorScheme.surfaceVariant,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$totalCalories',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'kcal',
                  style: theme.textTheme.bodyMedium,
                ),
                if (goalCals != null)
                  Text(
                    '/ $goalCals',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }


    Widget buildMacroBar({
      required String label,
      required double value,
      required double? goalValue,
      required String unit,
      required Color color,
    }) {
      final hasGoal = goalValue != null && goalValue > 0;
      final progress = hasGoal ? (value / goalValue!).clamp(0.0, 1.0) : 0.0;
      final displayValue = value.toStringAsFixed(0);
      final displayGoal = hasGoal ? goalValue!.toStringAsFixed(0) : null;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label),
                Text(
                  displayGoal == null
                      ? '$displayValue $unit'
                      : '$displayValue / $displayGoal $unit',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: hasGoal ? progress : 0,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      );
    }

        String _weekdayLabel(DateTime d) {
          const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
          return labels[d.weekday - 1];
        }

        Widget buildWeeklyCaloriesChart() {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This week',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 110,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: weekDays.map((day) {
                        final value = caloriesPerDay[day] ?? 0;
                        final ratio =
                            (value / maxForScale).clamp(0.0, 1.0).toDouble();
                        final isToday = _sameDay(day, now);

                        final barColor = isToday
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withOpacity(0.6);

                        return Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Number on top (optional, small)
                              Text(
                                value == 0 ? '' : value.toString(),
                                style: theme.textTheme.labelSmall,
                              ),
                              const SizedBox(height: 4),
                              // Bar
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    width: 10,
                                    height: 80 * ratio,
                                    decoration: BoxDecoration(
                                      color: barColor,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _weekdayLabel(day),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (goal?.calories != null)
                    Text(
                      'Bars show calories eaten each day vs your goal of '
                      '${goal!.calories} kcal.',
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    Text(
                      'Bars show calories eaten over the last 7 days.',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          );
        }

    final sortedMeals = List<MealEntry>.from(meals)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime)); // newest first

    final sortedSupps = List<SupplementEntry>.from(supplements)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            tooltip: 'Set nutrition goals',
            onPressed: () => _showEditGoalDialog(context),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'fab_supp',
            onPressed: () => _showAddSupplementDialog(context),
            child: const Icon(Icons.medication),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'fab_meal',
            onPressed: () async {
              final entry = await Navigator.of(context).push<MealEntry>(
                MaterialPageRoute(
                  builder: (_) => const LogMealScreen(),
                ),
              );
              if (entry != null) {
                onAddMeal(entry);
              }
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Today',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          // === NEW DASHBOARD CARD ===
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calories & macros',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  // 1) Calorie ring + macro bars
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildCalorieRing(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            buildMacroBar(
                              label: 'Protein',
                              value: totalProtein,
                              goalValue: goal?.protein,
                              unit: 'g',
                              color: proteinColor,
                            ),
                            buildMacroBar(
                              label: 'Carbs',
                              value: totalCarbs,
                              goalValue: goal?.carbs,
                              unit: 'g',
                              color: carbsColor,
                            ),
                            buildMacroBar(
                              label: 'Fat',
                              value: totalFat,
                              goalValue: goal?.fat,
                              unit: 'g',
                              color: fatColor,
                            ),
                            buildMacroBar(
                              label: 'Fiber',
                              value: totalFiber,
                              goalValue: goal?.fiber,
                              unit: 'g',
                              color: fiberColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2) Macro breakdown pie + legend
                  if (macroTotal > 0)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CustomPaint(
                            painter: _MacroBreakdownPainter(
                              values: macroValues,
                              colors: macroColors,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _macroLegendRow(
                                'Protein',
                                totalProtein,
                                'g',
                                proteinColor,
                                theme,
                              ),
                              _macroLegendRow(
                                'Carbs',
                                totalCarbs,
                                'g',
                                carbsColor,
                                theme,
                              ),
                              _macroLegendRow(
                                'Fat',
                                totalFat,
                                'g',
                                fatColor,
                                theme,
                              ),
                              _macroLegendRow(
                                'Fiber',
                                totalFiber,
                                'g',
                                fiberColor,
                                theme,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 12),
                  Text(
                    goal == null
                        ? 'No daily goal set. Tap the flag icon to set calories & macros.'
                        : 'Rings & bars show progress towards your daily goals. Protein goal also feeds into recovery estimates on the Stats page.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 🔹 Weekly calories chart
          buildWeeklyCaloriesChart(),

          const SizedBox(height: 16),

          // Today's supplements
          Text(
            'Supplements today',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (todaysSupplements.isEmpty)
            Text(
              'No supplements logged today.',
              style: theme.textTheme.bodySmall,
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: todaysSupplements.map((s) {
                    final dose = s.dose != null
                        ? '${s.dose!.toStringAsFixed(1)}${s.unit ?? ''}'
                        : null;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _showEditSupplementDialog(context, s),
                      title: Text(s.name),
                      subtitle: Text(
                        [
                          supplementCategoryLabel(s.category),
                          if (dose != null) dose,
                          if (s.notes != null && s.notes!.isNotEmpty) s.notes!,
                        ].join(' • '),
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          onDeleteSupplement(s);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Supplement deleted.'),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          const SizedBox(height: 16),

          Text(
            'Meals',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          if (sortedMeals.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No meals logged yet.\nTap + to log your first meal.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...sortedMeals.map((m) {
              final macroLines = <String>[];
              if (m.calories != null) {
                macroLines.add('${m.calories} kcal');
              }
              if (m.protein != null) {
                macroLines.add('P ${m.protein!.toStringAsFixed(0)}g');
              }
              if (m.carbs != null) {
                macroLines.add('C ${m.carbs!.toStringAsFixed(0)}g');
              }
              if (m.fat != null) {
                macroLines.add('F ${m.fat!.toStringAsFixed(0)}g');
              }
              if (m.fiber != null) {
                macroLines.add('Fib ${m.fiber!.toStringAsFixed(0)}g');
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    onTap: () => _showEditMealDialog(context, m),
                    title: Text(m.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDateTime(m.dateTime),
                          style: theme.textTheme.bodySmall,
                        ),
                        if (macroLines.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              macroLines.join(' • '),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        if (m.notes != null && m.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              m.notes!,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        if (m.items.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Items:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          ...m.items.map((it) {
                            final parts = <String>[];
                            if (it.calories != null) {
                              parts.add('${it.calories} kcal');
                            }
                            if (it.protein != null) {
                              parts.add(
                                  'P ${it.protein!.toStringAsFixed(0)}g');
                            }
                            if (it.carbs != null) {
                              parts.add(
                                  'C ${it.carbs!.toStringAsFixed(0)}g');
                            }
                            if (it.fat != null) {
                              parts.add(
                                  'F ${it.fat!.toStringAsFixed(0)}g');
                            }
                            if (it.fiber != null) {
                              parts.add(
                                  'Fib ${it.fiber!.toStringAsFixed(0)}g');
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '• ${it.name}'
                                '${parts.isNotEmpty ? ' (${parts.join(' • ')})' : ''}',
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        onDeleteMeal(m);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Meal deleted.'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }).toList(),

          const SizedBox(height: 16),

          Text(
            'All supplements',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (sortedSupps.isEmpty)
            const Text('No supplements logged yet.')
          else
            ...sortedSupps.map((s) {
              final dose = s.dose != null
                  ? '${s.dose!.toStringAsFixed(1)}${s.unit ?? ''}'
                  : null;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  onTap: () => _showEditSupplementDialog(context, s),
                  title: Text(s.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDateTime(s.dateTime),
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        [
                          supplementCategoryLabel(s.category),
                          if (dose != null) dose,
                          if (s.notes != null && s.notes!.isNotEmpty)
                            s.notes!,
                        ].join(' • '),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      onDeleteSupplement(s);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Supplement deleted.'),
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

Widget _macroLegendRow(
  String label,
  double value,
  String unit,
  Color color,
  ThemeData theme,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ),
        Text(
          '${value.toStringAsFixed(0)} $unit',
          style: theme.textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _MacroBreakdownPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _MacroBreakdownPainter({
    required this.values,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, v) => sum + v);
    if (total <= 0) return;

    final strokeWidth = size.width * 0.18;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2; // start at top
    for (int i = 0; i < values.length; i++) {
      final value = values[i];
      if (value <= 0) continue;

      final sweepAngle = (value / total) * 2 * math.pi;
      paint.color = colors[i % colors.length];

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _MacroBreakdownPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.colors != colors;
  }
}

