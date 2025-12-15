// lib/screens/log_meal_screen.dart

import 'package:flutter/material.dart';

import '../models.dart';

class _MealItem {
  String name;
  int? calories;
  double? protein;
  double? carbs;
  double? fat;
  double? fiber;

  // NEW: amount & servings (UI-only for now)
  double? amount;      // total amount for this portion (e.g. 200 g)
  String? unit;        // g, ml, piece, etc.
  double servings;     // number of servings used for this portion

  _MealItem({
    required this.name,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.amount,
    this.unit,
    this.servings = 1.0,
  });
}

class LogMealScreen extends StatefulWidget {
  final MealEntry? initialMeal;
  final NutritionGoal? nutritionGoal;

  // 🔹 NEW: cookbook support
  final List<CookbookMeal> cookbookMeals;
  final void Function(CookbookMeal)? onSaveToCookbook;

  const LogMealScreen({
    super.key,
    this.initialMeal,
    this.nutritionGoal,
    required this.cookbookMeals,
    this.onSaveToCookbook,
  });

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class FoodMacroLogScreen extends StatefulWidget {
  final _MealItem? initialItem;
  final NutritionGoal? nutritionGoal;

  const FoodMacroLogScreen({
    super.key,
    this.initialItem,
    this.nutritionGoal,
  });

  @override
  State<FoodMacroLogScreen> createState() => _FoodMacroLogScreenState();
}

class _FoodMacroLogScreenState extends State<FoodMacroLogScreen> {
  late TextEditingController _nameController;
  late TextEditingController _amountPerServingController;
  late TextEditingController _servingsController;
  late TextEditingController _caloriesPerServingController;
  late TextEditingController _proteinPerServingController;
  late TextEditingController _carbsPerServingController;
  late TextEditingController _fatPerServingController;
  late TextEditingController _fiberPerServingController;

  String _unit = 'g';

  double? _totalCalories;
  double? _totalProtein;
  double? _totalCarbs;
  double? _totalFat;
  double? _totalFiber;
  double? _totalAmount;

  @override
  void initState() {
    super.initState();
    final it = widget.initialItem;
    final servings = it?.servings ?? 1.0;

    double? _perServing(num? total) {
      if (total == null) return null;
      if (servings <= 0) return total.toDouble();
      return total.toDouble() / servings;
    }

    _nameController = TextEditingController(text: it?.name ?? '');
    _amountPerServingController = TextEditingController(
      text: _formatNumberIfNotNull(_perServing(it?.amount)),
    );
    _servingsController = TextEditingController(
      text: _formatNumber(servings),
    );
    _unit = it?.unit ?? 'g';

    _caloriesPerServingController = TextEditingController(
      text: _formatNumberIfNotNull(_perServing(it?.calories)),
    );
    _proteinPerServingController = TextEditingController(
      text: _formatNumberIfNotNull(_perServing(it?.protein)),
    );
    _carbsPerServingController = TextEditingController(
      text: _formatNumberIfNotNull(_perServing(it?.carbs)),
    );
    _fatPerServingController = TextEditingController(
      text: _formatNumberIfNotNull(_perServing(it?.fat)),
    );
    _fiberPerServingController = TextEditingController(
      text: _formatNumberIfNotNull(_perServing(it?.fiber)),
    );

    _recomputeTotals();
  }

  String _formatNumber(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  String _formatNumberIfNotNull(double? v) {
    if (v == null) return '';
    return _formatNumber(v);
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

  void _recomputeTotals() {
    final servings = _parseDouble(_servingsController.text) ?? 1.0;
    final perCal = _parseInt(_caloriesPerServingController.text) ?? 0;
    final perProt = _parseDouble(_proteinPerServingController.text) ?? 0.0;
    final perCarb = _parseDouble(_carbsPerServingController.text) ?? 0.0;
    final perFat = _parseDouble(_fatPerServingController.text) ?? 0.0;
    final perFib = _parseDouble(_fiberPerServingController.text) ?? 0.0;
    final perAmount = _parseDouble(_amountPerServingController.text);

    _totalCalories = perCal * servings;
    _totalProtein = perProt * servings;
    _totalCarbs = perCarb * servings;
    _totalFat = perFat * servings;
    _totalFiber = perFib * servings;
    _totalAmount = perAmount == null ? null : perAmount * servings;
  }

  void _saveAndClose() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a food name.')),
      );
      return;
    }

    final servings = _parseDouble(_servingsController.text) ?? 1.0;
    if (servings <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Servings must be greater than 0.')),
      );
      return;
    }

    final perCal = _parseInt(_caloriesPerServingController.text) ?? 0;
    final perProt = _parseDouble(_proteinPerServingController.text) ?? 0.0;
    final perCarb = _parseDouble(_carbsPerServingController.text) ?? 0.0;
    final perFat = _parseDouble(_fatPerServingController.text) ?? 0.0;
    final perFib = _parseDouble(_fiberPerServingController.text) ?? 0.0;
    final perAmount = _parseDouble(_amountPerServingController.text);

    final totalCalories =
        perCal == 0 ? null : (perCal * servings).round();
    final totalProtein = perProt == 0
        ? null
        : double.parse((perProt * servings).toStringAsFixed(1));
    final totalCarbs = perCarb == 0
        ? null
        : double.parse((perCarb * servings).toStringAsFixed(1));
    final totalFat = perFat == 0
        ? null
        : double.parse((perFat * servings).toStringAsFixed(1));
    final totalFiber = perFib == 0
        ? null
        : double.parse((perFib * servings).toStringAsFixed(1));
    final totalAmount = perAmount == null ? null : perAmount * servings;

    final item = _MealItem(
      name: name,
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      fiber: totalFiber,
      amount: totalAmount,
      unit: _unit,
      servings: servings,
    );

    Navigator.of(context).pop(item);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountPerServingController.dispose();
    _servingsController.dispose();
    _caloriesPerServingController.dispose();
    _proteinPerServingController.dispose();
    _carbsPerServingController.dispose();
    _fatPerServingController.dispose();
    _fiberPerServingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = widget.nutritionGoal;

    final totalCals = _totalCalories ?? 0;
    final totalProt = _totalProtein ?? 0;
    final totalCarb = _totalCarbs ?? 0;
    final totalFat = _totalFat ?? 0;

    double _ratio(num value, num? g) {
      if (g == null || g <= 0) return 0;
      final r = value / g;
      if (r < 0) return 0;
      if (r > 2) return 2;
      return r.toDouble();
    }

    final calRatio = _ratio(totalCals, goal?.calories);
    final protRatio = _ratio(totalProt, goal?.protein);
    final carbRatio = _ratio(totalCarb, goal?.carbs);
    final fatRatio = _ratio(totalFat, goal?.fat);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialItem == null ? 'Log food' : 'Edit food'),
        actions: [
          TextButton(
            onPressed: _saveAndClose,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Food name',
              hintText: 'e.g. Chicken breast',
            ),
          ),
          const SizedBox(height: 16),

          // Amount + unit + servings
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountPerServingController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount per serving',
                    hintText: 'e.g. 100',
                  ),
                  onChanged: (_) {
                    setState(_recomputeTotals);
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _unit,
                items: const [
                  DropdownMenuItem(value: 'g', child: Text('g')),
                  DropdownMenuItem(value: 'ml', child: Text('ml')),
                  DropdownMenuItem(value: 'piece', child: Text('piece')),
                  DropdownMenuItem(value: 'serving', child: Text('serving')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _unit = v;
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _servingsController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Servings',
                    hintText: 'e.g. 1, 2, 0.5',
                  ),
                  onChanged: (_) {
                    setState(_recomputeTotals);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Macros per serving',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _caloriesPerServingController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: false),
            decoration: const InputDecoration(
              labelText: 'Calories (kcal)',
              hintText: 'e.g. 200',
            ),
            onChanged: (_) {
              setState(_recomputeTotals);
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _proteinPerServingController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Protein (g)',
                  ),
                  onChanged: (_) {
                    setState(_recomputeTotals);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _carbsPerServingController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Carbs (g)',
                  ),
                  onChanged: (_) {
                    setState(_recomputeTotals);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fatPerServingController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Fat (g)',
                  ),
                  onChanged: (_) {
                    setState(_recomputeTotals);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _fiberPerServingController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Fiber (g)',
                  ),
                  onChanged: (_) {
                    setState(_recomputeTotals);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Summary + Impact on targets
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This portion',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${totalCals.toStringAsFixed(0)} kcal'
                    ' • P ${totalProt.toStringAsFixed(0)} g'
                    ' • C ${totalCarb.toStringAsFixed(0)} g'
                    ' • F ${totalFat.toStringAsFixed(0)} g',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (_totalAmount != null && _totalAmount! > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_totalAmount!.toStringAsFixed(0)} $_unit total',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Impact on targets',
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TargetRing(
                        label: 'Calories',
                        value: totalCals,
                        goal: goal?.calories?.toDouble(),
                        ratio: calRatio,
                        unit: 'kcal',
                      ),
                      _TargetRing(
                        label: 'Protein',
                        value: totalProt,
                        goal: goal?.protein,
                        ratio: protRatio,
                        unit: 'g',
                      ),
                      _TargetRing(
                        label: 'Carbs',
                        value: totalCarb,
                        goal: goal?.carbs,
                        ratio: carbRatio,
                        unit: 'g',
                      ),
                      _TargetRing(
                        label: 'Fat',
                        value: totalFat,
                        goal: goal?.fat,
                        ratio: fatRatio,
                        unit: 'g',
                      ),
                    ],
                  ),
                  if (goal == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Set daily nutrition goals to see impact percentages.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAndClose,
        icon: const Icon(Icons.check),
        label: const Text('Log food'),
      ),
    );
  }
}

class _TargetRing extends StatelessWidget {
  final String label;
  final double value;
  final double? goal;
  final double ratio;
  final String unit;

  const _TargetRing({
    required this.label,
    required this.value,
    required this.goal,
    required this.ratio,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasGoal = goal != null && goal! > 0;
    final pct =
        hasGoal ? (ratio * 100).clamp(0.0, 200.0).toStringAsFixed(0) : '--';

    return SizedBox(
      width: 70,
      child: Column(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: hasGoal ? ratio.clamp(0.0, 1.0) : 0,
                  strokeWidth: 5,
                  backgroundColor: colorScheme.surfaceVariant,
                ),
                Text(
                  hasGoal ? '$pct%' : '--',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


class _LogMealScreenState extends State<LogMealScreen> {
  late TextEditingController _titleController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _fiberController;
  late TextEditingController _notesController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  late List<_MealItem> _items;
  late MealType _mealType;

  bool _saveToCookbook = false;

  String? _selectedCookbookMealId;
  late TextEditingController _cookbookSearchController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMeal;

    _titleController = TextEditingController(text: initial?.title ?? '');
    _caloriesController =
        TextEditingController(text: initial?.calories?.toString() ?? '');
    _proteinController = TextEditingController(
      text: initial?.protein?.toStringAsFixed(0) ?? '',
    );
    _carbsController = TextEditingController(
      text: initial?.carbs?.toStringAsFixed(0) ?? '',
    );
    _fatController = TextEditingController(
      text: initial?.fat?.toStringAsFixed(0) ?? '',
    );
    _fiberController = TextEditingController(
      text: initial?.fiber?.toStringAsFixed(0) ?? '',
    );
    _notesController = TextEditingController(text: initial?.notes ?? '');

    _cookbookSearchController = TextEditingController();

    final dt = initial?.dateTime ?? DateTime.now();
    _selectedDate = DateTime(dt.year, dt.month, dt.day);
    _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);

    _items = (initial?.items ?? [])
        .map(
          (it) => _MealItem(
            name: it.name,
            calories: it.calories,
            protein: it.protein,
            carbs: it.carbs,
            fat: it.fat,
            fiber: it.fiber,
          ),
        )
        .toList();

    _mealType = initial?.mealType ?? MealType.other;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _notesController.dispose();
    _cookbookSearchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _addOrEditItem({_MealItem? existing, int? index}) async {
    final result = await Navigator.of(context).push<_MealItem>(
      MaterialPageRoute(
        builder: (_) => FoodMacroLogScreen(
          initialItem: existing,
          nutritionGoal: widget.nutritionGoal,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      if (existing != null && index != null) {
        _items[index] = result;
      } else {
        _items.add(result);
      }
    });
  }

  // 🔹 Apply a cookbook meal into this log screen
  void _applyCookbookMeal(CookbookMeal meal) {
    setState(() {
      // Only overwrite the title if empty
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = meal.title;
      }

      // Convert components into _MealItem list
      _items = meal.items
          .map(
            (it) => _MealItem(
              name: it.name,
              calories: it.calories,
              protein: it.protein,
              carbs: it.carbs,
              fat: it.fat,
              fiber: it.fiber,
            ),
          )
          .toList();

      // Recompute totals into the top-level fields
      int sumCals = 0;
      double sumProt = 0;
      double sumCarbs = 0;
      double sumFat = 0;
      double sumFiber = 0;

      for (final it in _items) {
        if (it.calories != null) sumCals += it.calories!;
        sumProt += it.protein ?? 0;
        sumCarbs += it.carbs ?? 0;
        sumFat += it.fat ?? 0;
        sumFiber += it.fiber ?? 0;
      }

      _caloriesController.text =
          sumCals == 0 ? '' : sumCals.toString();
      _proteinController.text =
          sumProt == 0 ? '' : sumProt.toStringAsFixed(1);
      _carbsController.text =
          sumCarbs == 0 ? '' : sumCarbs.toStringAsFixed(1);
      _fatController.text =
          sumFat == 0 ? '' : sumFat.toStringAsFixed(1);
      _fiberController.text =
          sumFiber == 0 ? '' : sumFiber.toStringAsFixed(1);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loaded "${meal.title}" from cookbook.')),
    );
  }

  List<CookbookMeal> get _filteredCookbookMeals {
    final query = _cookbookSearchController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.cookbookMeals;

    return widget.cookbookMeals.where((m) {
      final t = m.title.toLowerCase();
      return t.contains(query);
    }).toList();
  }

  void _saveMeal() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a meal name.'),
        ),
      );
      return;
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

    int? calories;
    double? protein;
    double? carbs;
    double? fat;
    double? fiber;

    if (_items.isNotEmpty) {
      int sumCals = 0;
      double sumProt = 0;
      double sumCarbs = 0;
      double sumFat = 0;
      double sumFiber = 0;

      for (final it in _items) {
        if (it.calories != null) sumCals += it.calories!;
        sumProt += it.protein ?? 0;
        sumCarbs += it.carbs ?? 0;
        sumFat += it.fat ?? 0;
        sumFiber += it.fiber ?? 0;
      }

      calories = sumCals == 0 ? null : sumCals;
      protein =
          sumProt == 0 ? null : double.parse(sumProt.toStringAsFixed(1));
      carbs =
          sumCarbs == 0 ? null : double.parse(sumCarbs.toStringAsFixed(1));
      fat = sumFat == 0 ? null : double.parse(sumFat.toStringAsFixed(1));
      fiber =
          sumFiber == 0 ? null : double.parse(sumFiber.toStringAsFixed(1));
    } else {
      calories = _parseInt(_caloriesController.text);
      protein = _parseDouble(_proteinController.text);
      carbs = _parseDouble(_carbsController.text);
      fat = _parseDouble(_fatController.text);
      fiber = _parseDouble(_fiberController.text);
    }

    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    final dt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final id = widget.initialMeal?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final entry = MealEntry(
      id: id,
      dateTime: dt,
      title: title,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      notes: notes,
      items: _items
          .map(
            (it) => MealComponent(
              name: it.name,
              calories: it.calories,
              protein: it.protein,
              carbs: it.carbs,
              fat: it.fat,
              fiber: it.fiber,
            ),
          )
          .toList(),
      mealType: _mealType,
    );

    // 🔹 Optionally save to cookbook
    if (_saveToCookbook && widget.onSaveToCookbook != null) {
      final cookbookMeal = CookbookMeal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        mealType: _mealType,
        items: entry.items,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
      );

      widget.onSaveToCookbook!(cookbookMeal);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to cookbook.')),
      );
    }

    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialMeal != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit meal' : 'Log a meal'),
        actions: [
          TextButton(
            onPressed: _saveMeal,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔹 Cookbook suggestions
          // 🔹 Cookbook: searchable dropdown
          if (widget.cookbookMeals.isNotEmpty) ...[
            Text(
              'From your cookbook',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),

            // Search box
            TextField(
              controller: _cookbookSearchController,
              decoration: const InputDecoration(
                labelText: 'Search recipes',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                setState(() {
                  // just rebuild to update _filteredCookbookMeals
                });
              },
            ),
            const SizedBox(height: 8),

            // Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCookbookMealId,
              decoration: const InputDecoration(
                labelText: 'Choose from cookbook',
                border: OutlineInputBorder(),
              ),
              items: _filteredCookbookMeals.map((meal) {
                return DropdownMenuItem<String>(
                  value: meal.id,
                  child: Text(
                    meal.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedCookbookMealId = value;
                });

                final matches = _filteredCookbookMeals
                    .where((m) => m.id == value)
                    .toList();
                if (matches.isNotEmpty) {
                  _applyCookbookMeal(matches.first);
                }
              },
            ),

            const SizedBox(height: 16),
          ],

          // Date & time row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    '${_selectedDate.day.toString().padLeft(2, '0')}/'
                    '${_selectedDate.month.toString().padLeft(2, '0')}/'
                    '${_selectedDate.year}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(_selectedTime.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Meal name',
              hintText: 'e.g. Breakfast, Chicken & rice',
            ),
          ),
          const SizedBox(height: 12),

          // Meal type selector
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Meal type',
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final type in [
                MealType.breakfast,
                MealType.lunch,
                MealType.dinner,
                MealType.snack,
                MealType.other,
              ])
                ChoiceChip(
                  label: Text(mealTypeLabel(type)),
                  selected: _mealType == type,
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() {
                      _mealType = type;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Totals (if you don\'t use items below)',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _caloriesController,
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
                  controller: _proteinController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Protein (g)',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _carbsController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
                  controller: _fatController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Fat (g)',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _fiberController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Fiber (g)',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes / ingredients (optional)',
              hintText: 'e.g. oats, whey, peanut butter...',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items',
                style: theme.textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: () => _addOrEditItem(),
                icon: const Icon(Icons.add),
                label: const Text('Add item'),
              ),
            ],
          ),
          const SizedBox(height: 4),

          if (_items.isEmpty)
            Text(
              'No food items added. You can fill in totals above, '
              'or add detailed items here.',
              style: theme.textTheme.bodySmall,
            )
          else
            ..._items.asMap().entries.map((entry) {
              final idx = entry.key;
              final it = entry.value;

              final parts = <String>[]; 
              if (it.calories != null) parts.add('${it.calories} kcal');
              if (it.protein != null) {
                parts.add('P ${it.protein!.toStringAsFixed(0)}g');
              }
              if (it.carbs != null) {
                parts.add('C ${it.carbs!.toStringAsFixed(0)}g');
              }
              if (it.fat != null) {
                parts.add('F ${it.fat!.toStringAsFixed(0)}g');
              }
              if (it.fiber != null) {
                parts.add('Fib ${it.fiber!.toStringAsFixed(0)}g');
              }

              if (it.amount != null && it.unit != null) {
                final amountText = it.amount!.toStringAsFixed(0);
                if (it.servings != 1.0) {
                  parts.add(
                    '${it.servings} × '
                    '${(it.amount! / it.servings).toStringAsFixed(0)} ${it.unit} '
                    '(${amountText} ${it.unit})',
                  );
                } else {
                  parts.add('$amountText ${it.unit}');
                }
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(it.name),
                  subtitle: parts.isEmpty
                      ? null
                      : Text(
                          parts.join(' • '),
                          style: theme.textTheme.bodySmall,
                        ),
                  onTap: () => _addOrEditItem(existing: it, index: idx),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() {
                        _items.removeAt(idx);
                      });
                    },
                  ),
                ),
              );
            }),

          const SizedBox(height: 16),

          // Save to cookbook toggle
          if (widget.onSaveToCookbook != null)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Save this meal to my cookbook'),
              value: _saveToCookbook,
              onChanged: (v) {
                setState(() {
                  _saveToCookbook = v ?? false;
                });
              },
            ),

          const SizedBox(height: 24),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveMeal,
        icon: const Icon(Icons.check),
        label: const Text('Save meal'),
      ),
    );
  }
}
