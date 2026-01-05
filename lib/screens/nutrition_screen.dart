// lib/screens/nutrition_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'log_meal_screen.dart';
import 'weight_trends_screen.dart';
import 'cookbook_screen.dart';
import 'weekly_goals_screen.dart';

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

enum EnergyViewMode { consumed, remaining }

class NutritionScreen extends StatefulWidget {
  final List<MealEntry> meals;
  final List<SupplementEntry> supplements;

  final List<WeightEntry> weightEntries;

  final void Function(MealEntry) onAddMeal;
  final void Function(MealEntry) onUpdateMeal;
  final void Function(MealEntry) onDeleteMeal;

  final void Function(SupplementEntry) onAddSupplement;
  final void Function(SupplementEntry) onUpdateSupplement;
  final void Function(SupplementEntry) onDeleteSupplement;

  final NutritionGoal? nutritionGoal;
  final void Function(NutritionGoal?) onUpdateGoal;

  final int? Function(DateTime) burnedForDate;
  final void Function(DateTime, int) onUpdateBurnedForDate;

  final List<CookbookMeal> cookbookMeals;
  final void Function(CookbookMeal) onAddCookbookMeal;

  final WeeklyNutritionGoals weeklyGoals;
  final void Function(WeeklyNutritionGoals) onUpdateWeeklyGoals;

  const NutritionScreen({
    super.key,
    required this.meals,
    required this.supplements,
    required this.weightEntries,
    required this.onAddMeal,
    required this.onUpdateMeal,
    required this.onDeleteMeal,
    required this.onAddSupplement,
    required this.onUpdateSupplement,
    required this.onDeleteSupplement,
    required this.nutritionGoal,
    required this.onUpdateGoal,
    required this.burnedForDate,
    required this.onUpdateBurnedForDate,
    required this.cookbookMeals,
    required this.onAddCookbookMeal,
    required this.weeklyGoals,
    required this.onUpdateWeeklyGoals,    
  });

  @override
State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  late DateTime _selectedDate;

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  EnergyViewMode _energyMode = EnergyViewMode.consumed;
  int _animTick = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(DateTime.now());
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = _dateOnly(picked);
        _animTick++; // 👈 restart animations
      });
    }
  }

  String _dayLabel(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

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
    widget.onAddSupplement(result);
  }


  Future<void> _showEditMealDialog(BuildContext context, MealEntry meal) async {
    // we now edit via LogMealScreen, not the simple dialog
    final updated = await Navigator.of(context).push<MealEntry>(
      MaterialPageRoute(
        builder: (_) => LogMealScreen(
          initialMeal: meal,
          nutritionGoal: widget.nutritionGoal,
          cookbookMeals: widget.cookbookMeals,         
          onSaveToCookbook: widget.onAddCookbookMeal,
        ),
      ),
    );

    if (updated == null) return;

    widget.onUpdateMeal(updated);
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

    widget.onUpdateSupplement(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Supplement updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = _selectedDate;
    final now = DateTime.now();

    bool _sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

        final todaysMeals = widget.meals.where((m) => _sameDay(m.dateTime, day));
        final todaysSupplements = widget.supplements.where((s) => _sameDay(s.dateTime, day)).toList();


    final todaysMealsList = todaysMeals.toList()
    ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

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

    // Weekly goals: per-day goal with fallback to the old single goal
    NutritionGoal? goalForDate(DateTime date) {
      return widget.weeklyGoals.forDate(date, fallback: widget.nutritionGoal);
    }

    final NutritionGoal? goal = goalForDate(day);
    final int? goalCalories = goal?.calories;

    final burned = widget.burnedForDate(day) ?? 0;
    // 🔹 local mode for the "Consumed / Remaining" toggle
    // EnergyViewMode energyMode = EnergyViewMode.consumed;

    // 🔹 colour for calorie ring based on % of goal eaten
    Color _calorieColor(double progress) {
      // 0 → blue, 0.5 → yellow, 1 → green
      if (progress <= 0.5) {
        final t = progress / 0.5;
        return Color.lerp(Colors.blue, Colors.yellow, t)!;
      } else {
        final t = (progress - 0.5) / 0.5;
        return Color.lerp(Colors.yellow, Colors.green, t)!;
      }
    }

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
    // final todayDate = DateTime(now.year, now.month, now.day);
    // final weekDays = List.generate(
    //   7,
    //   (i) => todayDate.subtract(Duration(days: 6 - i)), // oldest -> today
    // );

    // final Map<DateTime, int> caloriesPerDay = {
    //   for (final d in weekDays) d: 0,
    // };

    // for (final meal in meals) {
    //   final d = DateTime(
    //     meal.dateTime.year,
    //     meal.dateTime.month,
    //     meal.dateTime.day,
    //   );
    //   if (!caloriesPerDay.containsKey(d)) continue;
    //   caloriesPerDay[d] = caloriesPerDay[d]! + (meal.calories ?? 0);
    // }

    // final maxDayCalories = caloriesPerDay.values.fold<int>(
    //   0,
    //   (max, v) => v > max ? v : max,
    // );

    // final double maxForScale = ([
    //   maxDayCalories.toDouble(),
    //   (goal?.calories?.toDouble() ?? 0),
    //   1.0,
    // ]..sort())
    //     .last; // pick the largest of (maxDay, goal, 1)

    const double _macroChartSize = 110.0; // use same size for ring + pie

    Widget buildCalorieRing(EnergyViewMode mode, double t) {
      final colorScheme = theme.colorScheme;

      final int? baseGoal = goalCalories;                 // nullable
      final bool hasGoal = baseGoal != null && baseGoal > 0;

      // If there is a goal, extend it by burned kcal.
      // If not, just scale to today's intake so we avoid div-by-zero.
      final int adjustedGoal = hasGoal
          ? baseGoal! + burned
          : (totalCalories > 0 ? totalCalories : 1);

      final int remaining =
          (adjustedGoal - totalCalories).clamp(0, adjustedGoal) as int;

      final double progressConsumed =
          (totalCalories / adjustedGoal).clamp(0.0, 1.0).toDouble();
      final double progressRemaining =
          (remaining / adjustedGoal).clamp(0.0, 1.0).toDouble();

      final bool isConsumed = mode == EnergyViewMode.consumed;
      final double ringProgress =
          isConsumed ? progressConsumed : progressRemaining;
      final int displayKcal = isConsumed ? totalCalories : remaining;
      final String subtitle = isConsumed ? 'kcal' : 'kcal left';

      final ringColor = _calorieColor(progressConsumed); // same gradient

      return SizedBox(
        width: _macroChartSize,
        height: _macroChartSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: ringProgress * t,
                strokeWidth: _macroChartSize * 0.18,
                valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                backgroundColor: colorScheme.surfaceVariant,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$displayKcal',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium,
                ),
                if (hasGoal)
                  Text(
                    '/ $adjustedGoal',
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
      required EnergyViewMode mode,
      required double t,
    }) {
      final hasGoal = goalValue != null && goalValue > 0;
      final progress = hasGoal ? (value / goalValue!).clamp(0.0, 1.0) : 0.0;
      final animatedProgress = progress * t;
      final displayValue = value.toStringAsFixed(0);
      final displayGoal = hasGoal ? goalValue!.toStringAsFixed(0) : null;

      double remaining = 0;
      if (hasGoal) {
        remaining = goalValue! - value;
        if (remaining < 0) remaining = 0;
      }

      String _buildLabel() {
        if (!hasGoal) return '$displayValue $unit';
        if (mode == EnergyViewMode.consumed) {
          return '$displayValue / $displayGoal $unit';
        } else {
          return '${remaining.toStringAsFixed(0)} $unit left';
        }
      }

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
                  _buildLabel(),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: hasGoal ? (progress * t) : 0,
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
      // --- calories & goals per day ---
      final todayDate = DateTime(now.year, now.month, now.day);
      final weekDays = List.generate(
        7,
        (i) => todayDate.subtract(Duration(days: 6 - i)), // oldest -> today
      );

      final Map<DateTime, int> caloriesPerDay = {
        for (final d in weekDays) d: 0,
      };

      for (final meal in widget.meals) {
        final d = DateTime(
          meal.dateTime.year,
          meal.dateTime.month,
          meal.dateTime.day,
        );
        if (!caloriesPerDay.containsKey(d)) continue;
        caloriesPerDay[d] = caloriesPerDay[d]! + (meal.calories ?? 0);
      }

      // Per-day goals (for now this just mirrors `goal`, but later you can
      // plug in weekday-specific goals via `goalForDate(date)`).
      final Map<DateTime, int> goalCaloriesPerDay = {
        for (final d in weekDays)
          d: goalForDate(d)?.calories ?? 0,
      };

      // Scale for bars (max of any actual or goal, plus a minimum of 1).
      double maxForScale = 1.0;
      for (final d in weekDays) {
        final actual = caloriesPerDay[d] ?? 0;
        final g = goalCaloriesPerDay[d] ?? 0;
        if (actual > maxForScale) maxForScale = actual.toDouble();
        if (g > maxForScale) maxForScale = g.toDouble();
      }

      // For consistency + micro trend line
      final ratios = <double>[];
      int onTargetDays = 0;

      for (final d in weekDays) {
        final actual = (caloriesPerDay[d] ?? 0).toDouble();
        final g = (goalCaloriesPerDay[d] ?? 0).toDouble();
        if (g > 0) {
          final r = actual / g;
          ratios.add(r);
          // Mark as "on target" if within ±10% of that day's goal.
          if ((actual - g).abs() <= g * 0.1 && actual > 0) {
            onTargetDays++;
          }
        } else {
          ratios.add(0.0);
        }
      }

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
                    final actual = (caloriesPerDay[day] ?? 0).toDouble();
                    final goalForDay =
                        (goalCaloriesPerDay[day] ?? 0).toDouble();

                    final actualRatio =
                        (actual / maxForScale).clamp(0.0, 1.0).toDouble();
                    final goalRatio =
                        (goalForDay / maxForScale).clamp(0.0, 1.0).toDouble();

                    final isToday = _sameDay(day, now);

                    final barColor = isToday
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withOpacity(0.7);

                    final goalColor =
                        theme.colorScheme.primary.withOpacity(0.20);

                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // kcal number on top (optional)
                          Text(
                            actual == 0 ? '' : actual.toInt().toString(),
                            style: theme.textTheme.labelSmall,
                          ),
                          const SizedBox(height: 4),
                          // Goal + actual bars stacked
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  // Goal "ghost" bar
                                  if (goalForDay > 0)
                                    Container(
                                      width: 10,
                                      height: 80 * goalRatio,
                                      decoration: BoxDecoration(
                                        color: goalColor,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                    ),
                                  // Actual bar on top
                                  Container(
                                    width: 10,
                                    height: 80 * actualRatio,
                                    decoration: BoxDecoration(
                                      color: barColor,
                                      borderRadius:
                                          BorderRadius.circular(999),
                                    ),
                                  ),
                                ],
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
              const SizedBox(height: 8),

              if (goal != null) ...[
                Text(
                  'On-target days (±10% of goal): $onTargetDays / 7',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _CalorieConsistencySparklinePainter(
                      ratios: ratios,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bars and line show each day\'s calories vs that day\'s goal.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (goal == null) ...[
                Text(
                  'Bars show calories eaten over the last 7 days.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      );
    }

    Widget buildWeightTrendCard() {
      if (widget.weightEntries.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Log your weight to see trends over the last 30 days.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        );
      }

      // Last 30 days
      final today = DateTime(now.year, now.month, now.day);
      final cutoff = today.subtract(const Duration(days: 30));

      final recent = widget.weightEntries
          .where((w) => w.date.isAfter(cutoff)) // assumes WeightEntry.date
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      if (recent.length < 2) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Once you have a few weight entries, '
              'we’ll show your 30-day trend here.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        );
      }

      final double start = recent.first.weightKg; // assumes WeightEntry.weightKg
      final double end = recent.last.weightKg;
      final double delta = end - start;

      final double minW =
          recent.map((w) => w.weightKg).reduce((a, b) => a < b ? a : b);
      final double maxW =
          recent.map((w) => w.weightKg).reduce((a, b) => a > b ? a : b);

      final double range = (maxW - minW).abs() < 1e-6 ? 1.0 : (maxW - minW);
      final double position = ((end - minW) / range).clamp(0.0, 1.0);

      String deltaText;
      if (delta.abs() < 0.05) {
        deltaText = 'no change';
      } else if (delta < 0) {
        deltaText = '${delta.abs().toStringAsFixed(1)} kg down';
      } else {
        deltaText = '${delta.toStringAsFixed(1)} kg up';
      }

      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WeightTrendsScreen(
                weightEntries: widget.weightEntries,
              ),
            ),
          );
        },
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weight trend (30 days)',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${start.toStringAsFixed(1)} kg → '
                  '${end.toStringAsFixed(1)} kg ($deltaText)',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Range: ${minW.toStringAsFixed(1)} – '
                  '${maxW.toStringAsFixed(1)} kg',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: position,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to see detailed trends and analytics.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }



    // final sortedMeals = List<MealEntry>.from(meals)
    //   ..sort((a, b) => b.dateTime.compareTo(a.dateTime)); // newest first

    final sortedSupps = List<SupplementEntry>.from(widget.supplements)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        actions: [
          // 🔹 Open cookbook screen
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Cookbook',
            onPressed: () async {
              final entry = await Navigator.of(context).push<MealEntry>(
                MaterialPageRoute(
                  builder: (_) => CookbookScreen(
                    cookbookMeals: widget.cookbookMeals,
                    nutritionGoal: widget.nutritionGoal,
                  ),
                ),
              );

              if (entry != null) {
                widget.onAddMeal(entry);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logged "${entry.title}" from cookbook.'),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.flag),
            tooltip: 'Weekly nutrition goals',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WeeklyGoalsScreen(
                    weeklyGoals: widget.weeklyGoals,
                    baseGoal: widget.nutritionGoal,
                    onSave: (newWeekly, newBase) {
                      widget.onUpdateWeeklyGoals(newWeekly);
                      widget.onUpdateGoal(newBase);
                    },
                  ),
                ),
              );
            },
          ),
        ]
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
                  builder: (_) => LogMealScreen(
                    nutritionGoal: widget.nutritionGoal,
                    cookbookMeals: widget.cookbookMeals,           // 🔹 NEW
                    onSaveToCookbook: widget.onAddCookbookMeal,   // 🔹 NEW
                  ),
                ),
              );
              if (entry != null) {
                widget.onAddMeal(entry);
              }
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                }),
              ),
              Expanded(
                child: Center(
                  child: InkWell(
                    onTap: _pickDay,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Text(
                        _dayLabel(_selectedDate),
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // === DASHBOARD CARD: Calories & macros with toggle ===
          Card(
            child: TweenAnimationBuilder<double>(
              key: ValueKey('dash_${_selectedDate.toIso8601String()}_$_animTick'),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (ctx, t, child) {
                final bool isConsumed = _energyMode == EnergyViewMode.consumed;

                int adjustedGoalLocal = 0;
                int remainingClamped = 0;

                if (goalCalories != null && goalCalories! > 0) {
                  adjustedGoalLocal = goalCalories! + burned;
                  final rawRemaining = adjustedGoalLocal - totalCalories;
                  remainingClamped = rawRemaining < 0 ? 0 : rawRemaining;
                }

                // ✅ Animated numbers
                final int animatedTotalCalories = (totalCalories * t).round();
                final double animatedProtein = totalProtein * t;
                final double animatedCarbs = totalCarbs * t;
                final double animatedFat = totalFat * t;
                final double animatedFiber = totalFiber * t;

                final int animatedRemaining =
                    (remainingClamped * t).round();

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calories & macros',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ✅ ring animates using t
                          buildCalorieRing(_energyMode, t),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                buildMacroBar(
                                  label: 'Protein',
                                  value: animatedProtein,
                                  goalValue: goal?.protein,
                                  unit: 'g',
                                  color: proteinColor,
                                  mode: _energyMode,
                                  t: t,
                                ),
                                buildMacroBar(
                                  label: 'Carbs',
                                  value: animatedCarbs,
                                  goalValue: goal?.carbs,
                                  unit: 'g',
                                  color: carbsColor,
                                  mode: _energyMode,
                                  t: t,
                                ),
                                buildMacroBar(
                                  label: 'Fat',
                                  value: animatedFat,
                                  goalValue: goal?.fat,
                                  unit: 'g',
                                  color: fatColor,
                                  mode: _energyMode,
                                  t: t,
                                ),
                                buildMacroBar(
                                  label: 'Fiber',
                                  value: animatedFiber,
                                  goalValue: goal?.fiber,
                                  unit: 'g',
                                  color: fiberColor,
                                  mode: _energyMode,
                                  t: t,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (goalCalories != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isConsumed ? 'Consumed' : 'Remaining',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              isConsumed
                                  ? '$animatedTotalCalories / $adjustedGoalLocal kcal'
                                  : '$animatedRemaining / $adjustedGoalLocal kcal',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: _buildEnergyToggle(
                            _energyMode,
                            theme,
                            (newMode) {
                              // keep your existing toggle behavior
                              setState(() {
                                _energyMode = newMode;
                              });
                              // optional: restart animation when toggling
                              // setState(() => _animTick++);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ✅ Pie animates using t
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
                                  t: t, // 👈 add this
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
                                    animatedProtein,
                                    'g',
                                    proteinColor,
                                    theme,
                                  ),
                                  _macroLegendRow(
                                    'Carbs',
                                    animatedCarbs,
                                    'g',
                                    carbsColor,
                                    theme,
                                  ),
                                  _macroLegendRow(
                                    'Fat',
                                    animatedFat,
                                    'g',
                                    fatColor,
                                    theme,
                                  ),
                                  _macroLegendRow(
                                    'Fiber',
                                    animatedFiber,
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
                );
              },
            ),
          ),


          const SizedBox(height: 16),

          // 🔹 Weekly calories chart
          buildWeeklyCaloriesChart(),

          const SizedBox(height: 16),

          buildWeightTrendCard(),

          const SizedBox(height: 16),


          // 🔥 Burned & balance card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Burned & balance',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // mini burned ring
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: goalCalories == null || goalCalories <= 0
                              ? null
                              : (burned / goalCalories!.toDouble())
                                  .clamp(0.0, 1.0),
                          strokeWidth: 8,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Burned today: $burned kcal'),
                            const SizedBox(height: 4),
                            Text(
                              'Net: ${totalCalories - burned} kcal '
                              '(${totalCalories} in – $burned out)',
                              style: theme.textTheme.bodySmall,
                            ),
                            if (goalCalories != null) ...[
                              const SizedBox(height: 4),
                              Builder(
                                builder: (_) {
                                  final int adjustedGoal =
                                      goalCalories! + burned;
                                  final int remainingVsAdjusted =
                                      (adjustedGoal - totalCalories) < 0
                                          ? 0
                                          : (adjustedGoal - totalCalories);
                                  return Text(
                                    'Remaining vs goal: '
                                    '$remainingVsAdjusted kcal',
                                    style: theme.textTheme.bodySmall,
                                  );
                                },
                              ),
                            ],
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton(
                                onPressed: () {
                                  _showEditBurnedDialog(
                                    context,
                                    burned,
                                    (val) => widget.onUpdateBurnedForDate(_selectedDate, val),
                                  );
                                },
                                child: const Text('Edit burned')
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

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
                          widget.onDeleteSupplement(s);
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
            'Meals today',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          ...[
            MealType.breakfast,
            MealType.lunch,
            MealType.dinner,
            MealType.snack,
            MealType.other,
          ].map((type) {
            final typeMeals = todaysMealsList
                .where((m) => m.mealType == type)
                .toList();

            final typeLabel = mealTypeLabel(type);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeLabel,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),

                  if (typeMeals.isEmpty)
                    Text(
                      'No ${typeLabel.toLowerCase()} logged today.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ...typeMeals.map((m) {
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
                                      padding:
                                          const EdgeInsets.only(top: 2),
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
                                widget.onDeleteMeal(m);
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
                ],
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
                      widget.onDeleteSupplement(s);
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

Widget _buildEnergyToggle(
  EnergyViewMode mode,
  ThemeData theme,
  ValueChanged<EnergyViewMode> onChanged,
) {
  return Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(999),
    ),
    child: SizedBox(
      height: 32,
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: mode == EnergyViewMode.consumed
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.background,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onChanged(EnergyViewMode.consumed),
                  child: Center(
                    child: Text(
                      'Consumed',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: mode == EnergyViewMode.consumed
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onChanged(EnergyViewMode.remaining),
                  child: Center(
                    child: Text(
                      'Remaining',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: mode == EnergyViewMode.remaining
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}


class _MacroBreakdownPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double t;

  _MacroBreakdownPainter({
    required this.values,
    required this.colors,
    this.t = 1.0,
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

      final sweepAngle = (value / total) * 2 * math.pi * t;
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

Future<void> _showEditBurnedDialog(
  BuildContext context,
  int current,
  void Function(int) onUpdate,
) async {
  final controller = TextEditingController(text: current.toString());
  int? _parseInt(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t.replaceAll(',', ''));
  }

  final result = await showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Calories burned today'),
      content: TextField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: false),
        decoration: const InputDecoration(
          labelText: 'Burned (kcal)',
          hintText: 'e.g. 500',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final val = _parseInt(controller.text) ?? 0;
            Navigator.of(ctx).pop(val);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );

  if (result != null) {
    onUpdate(result);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Burned calories updated.')),
    );
  }
}

class _CalorieConsistencySparklinePainter extends CustomPainter {
  final List<double> ratios; // actual / goal per day (0..something)
  final Color color;

  _CalorieConsistencySparklinePainter({
    required this.ratios,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (ratios.isEmpty) return;

    // Clamp ratios to a sensible range, e.g. 0..2 (0–200% of goal).
    final clamped = ratios
        .map((r) => r.isFinite ? r.clamp(0.0, 2.0) as double : 0.0)
        .toList();

    double minR = clamped.reduce(math.min);
    double maxR = clamped.reduce(math.max);

    // Make sure we have a vertical span.
    if ((maxR - minR).abs() < 0.05) {
      // If almost flat, give it a tiny span so the line is visible.
      minR = (minR - 0.05).clamp(0.0, 2.0);
      maxR = (maxR + 0.05).clamp(0.0, 2.0);
    }

    final span = maxR - minR;

    final path = Path();
    final dx = clamped.length == 1
        ? 0.0
        : size.width / (clamped.length - 1);

    for (int i = 0; i < clamped.length; i++) {
      final r = clamped[i];
      final x = dx * i;
      // Map ratio to y (0 = top, 1 = bottom in canvas space)
      final t = (r - minR) / span;
      final y = size.height * (1.0 - t);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;

    // Optional baseline at 1.0 (100% of goal) if within visible range.
    if (1.0 >= minR && 1.0 <= maxR) {
      final tBase = (1.0 - minR) / span;
      final yBase = size.height * (1.0 - tBase);

      final baselinePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withOpacity(0.3);

      canvas.drawLine(
        Offset(0, yBase),
        Offset(size.width, yBase),
        baselinePaint,
      );
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(
    covariant _CalorieConsistencySparklinePainter oldDelegate,
  ) {
    return oldDelegate.ratios != ratios || oldDelegate.color != color;
  }
}



