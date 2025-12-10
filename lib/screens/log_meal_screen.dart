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

  _MealItem({
    required this.name,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
  });
}

class LogMealScreen extends StatefulWidget {
  /// If null → creating a new meal.
  /// If non-null → editing an existing meal.
  final MealEntry? initialMeal;

  const LogMealScreen({super.key, this.initialMeal});

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
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
    final nameController = TextEditingController(text: existing?.name ?? '');
    final caloriesController =
        TextEditingController(text: existing?.calories?.toString() ?? '');
    final proteinController =
        TextEditingController(text: existing?.protein?.toString() ?? '');
    final carbsController =
        TextEditingController(text: existing?.carbs?.toString() ?? '');
    final fatController =
        TextEditingController(text: existing?.fat?.toString() ?? '');
    final fiberController =
        TextEditingController(text: existing?.fiber?.toString() ?? '');

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

    final result = await showDialog<_MealItem>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add food item' : 'Edit food item'),
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
                _MealItem(
                  name: name,
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

    setState(() {
      if (existing != null && index != null) {
        _items[index] = result;
      } else {
        _items.add(result);
      }
    });
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

    final notes =
        _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

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

          // NEW: Meal type selector
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
                  onTap: () =>
                      _addOrEditItem(existing: it, index: idx),
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
