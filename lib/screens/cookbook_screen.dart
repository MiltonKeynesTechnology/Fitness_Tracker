// lib/screens/cookbook_screen.dart

import 'package:flutter/material.dart';

import '../models.dart';
import 'log_meal_screen.dart';

class CookbookScreen extends StatefulWidget {
  final List<CookbookMeal> cookbookMeals;
  final NutritionGoal? nutritionGoal;

  const CookbookScreen({
    super.key,
    required this.cookbookMeals,
    this.nutritionGoal,
  });

  @override
  State<CookbookScreen> createState() => _CookbookScreenState();
}

class _CookbookScreenState extends State<CookbookScreen> {
  late TextEditingController _searchController;
  MealType? _filterType;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CookbookMeal> get _filteredMeals {
    final query = _searchController.text.trim().toLowerCase();

    final list = widget.cookbookMeals.where((m) {
      // Filter by meal type if selected
      if (_filterType != null && m.mealType != _filterType) return false;

      if (query.isEmpty) return true;

      final title = m.title.toLowerCase();
      final itemsText = m.items
          .map((c) => c.name.toLowerCase())
          .join(' ');

      return title.contains(query) || itemsText.contains(query);
    }).toList();

    // Sort by title for a stable order
    list.sort((a, b) =>
        a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return list;
  }

  Future<void> _logFromCookbook(CookbookMeal meal) async {
    final now = DateTime.now();

    // Build a temporary MealEntry from the cookbook meal
    final tempMeal = MealEntry(
      id: now.millisecondsSinceEpoch.toString(),
      dateTime: now,
      title: meal.title,
      calories: meal.calories,
      protein: meal.protein,
      carbs: meal.carbs,
      fat: meal.fat,
      fiber: meal.fiber,
      notes: null,
      items: meal.items,
      mealType: meal.mealType,
    );

    // Let the user tweak it in LogMealScreen
    final result = await Navigator.of(context).push<MealEntry>(
      MaterialPageRoute(
        builder: (_) => LogMealScreen(
          initialMeal: tempMeal,
          nutritionGoal: widget.nutritionGoal,
          cookbookMeals: widget.cookbookMeals,
        ),
      ),
    );

    // If they saved, bubble the MealEntry back to the caller (NutritionScreen)
    if (result != null) {
      Navigator.of(context).pop(result);
    }
  }

  String _macroSummary(CookbookMeal m) {
    final parts = <String>[];
    if (m.calories != null) parts.add('${m.calories} kcal');
    if (m.protein != null) {
      parts.add('P ${m.protein!.toStringAsFixed(0)}g');
    }
    if (m.carbs != null) {
      parts.add('C ${m.carbs!.toStringAsFixed(0)}g');
    }
    if (m.fat != null) {
      parts.add('F ${m.fat!.toStringAsFixed(0)}g');
    }
    if (m.fiber != null) {
      parts.add('Fib ${m.fiber!.toStringAsFixed(0)}g');
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meals = _filteredMeals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cookbook'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search field
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search recipes',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                setState(() {
                  // rebuild with new filter
                });
              },
            ),
            const SizedBox(height: 12),

            // Meal type filter chips
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip(null, 'All'),
                  _buildFilterChip(
                    MealType.breakfast,
                    mealTypeLabel(MealType.breakfast),
                  ),
                  _buildFilterChip(
                    MealType.lunch,
                    mealTypeLabel(MealType.lunch),
                  ),
                  _buildFilterChip(
                    MealType.dinner,
                    mealTypeLabel(MealType.dinner),
                  ),
                  _buildFilterChip(
                    MealType.snack,
                    mealTypeLabel(MealType.snack),
                  ),
                  _buildFilterChip(
                    MealType.other,
                    mealTypeLabel(MealType.other),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // List of cookbook meals
            if (meals.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    widget.cookbookMeals.isEmpty
                        ? 'You haven\'t saved any meals yet.\nTurn on "Save this meal to my cookbook" when logging a meal.'
                        : 'No recipes match your search/filter.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    final macro = _macroSummary(meal);
                    final itemsCount = meal.items.length;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(meal.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mealTypeLabel(meal.mealType),
                              style: theme.textTheme.bodySmall,
                            ),
                            if (macro.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  macro,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '$itemsCount item${itemsCount == 1 ? '' : 's'}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _logFromCookbook(meal),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(MealType? type, String label) {
    final bool selected =
        type == null ? _filterType == null : _filterType == type;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _filterType = type;
        });
      },
    );
  }
}
