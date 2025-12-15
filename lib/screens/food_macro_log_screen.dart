// lib/screens/food_macro_log_screen.dart

import 'package:flutter/material.dart';
import '../models.dart'; // for NutritionGoal

enum _ActiveMacroField { calories, protein, carbs, fat }

class FoodMacroLogScreen extends StatefulWidget {
  final String initialName;

  // initial macros for this portion (for editing existing item)
  final int? initialCalories;
  final double? initialProtein;
  final double? initialCarbs;
  final double? initialFat;
  final double? initialFiber;

  // for “impact on targets”
  final NutritionGoal? nutritionGoal;

  const FoodMacroLogScreen({
    super.key,
    required this.initialName,
    this.initialCalories,
    this.initialProtein,
    this.initialCarbs,
    this.initialFat,
    this.initialFiber,
    required this.nutritionGoal,
  });

  @override
  State<FoodMacroLogScreen> createState() => _FoodMacroLogScreenState();
}

class _FoodMacroLogScreenState extends State<FoodMacroLogScreen> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  String _unit = 'g';

  late TextEditingController _calController;
  late TextEditingController _pController;
  late TextEditingController _cController;
  late TextEditingController _fController;
  late TextEditingController _fibController;

  _ActiveMacroField _activeField = _ActiveMacroField.calories;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName);
    _amountController = TextEditingController(text: '1.0');

    _calController = TextEditingController(
      text: widget.initialCalories?.toString() ?? '',
    );
    _pController = TextEditingController(
      text: widget.initialProtein?.toStringAsFixed(0) ?? '',
    );
    _cController = TextEditingController(
      text: widget.initialCarbs?.toStringAsFixed(0) ?? '',
    );
    _fController = TextEditingController(
      text: widget.initialFat?.toStringAsFixed(0) ?? '',
    );
    _fibController = TextEditingController(
      text: widget.initialFiber?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _calController.dispose();
    _pController.dispose();
    _cController.dispose();
    _fController.dispose();
    _fibController.dispose();
    super.dispose();
  }

  int? _parseInt(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t.replaceAll(',', ''));
  }

  double? _parseDouble(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  TextEditingController _controllerForActive() {
    switch (_activeField) {
      case _ActiveMacroField.calories:
        return _calController;
      case _ActiveMacroField.protein:
        return _pController;
      case _ActiveMacroField.carbs:
        return _cController;
      case _ActiveMacroField.fat:
        return _fController;
    }
  }

  void _onKeyTap(String key) {
    final ctrl = _controllerForActive();
    final text = ctrl.text;

    if (key == '⌫') {
      if (text.isNotEmpty) {
        ctrl.text = text.substring(0, text.length - 1);
      }
      return;
    }

    if (key == '.' && text.contains('.')) {
      return; // only one decimal point
    }

    ctrl.text = '$text$key';
  }

  Widget _buildImpactChip({
    required String label,
    required double? portion,
    required double? goal,
    required Color color,
    required ThemeData theme,
  }) {
    if (goal == null || goal <= 0 || portion == null) {
      return Column(
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              value: 0,
              strokeWidth: 4,
              backgroundColor: theme.colorScheme.surfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.labelSmall),
          Text('--', style: theme.textTheme.labelSmall),
        ],
      );
    }

    final ratio = (portion / goal).clamp(0.0, 2.0);
    final percent = (portion / goal * 100).toStringAsFixed(0);

    return Column(
      children: [
        SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(
            value: ratio > 1 ? 1.0 : ratio,
            strokeWidth: 4,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.labelSmall),
        Text(
          '$percent%',
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = widget.nutritionGoal;

    final calories = _parseInt(_calController.text) ?? 0;
    final protein = _parseDouble(_pController.text) ?? 0;
    final carbs = _parseDouble(_cController.text) ?? 0;
    final fat = _parseDouble(_fController.text) ?? 0;
    final fiber = _parseDouble(_fibController.text) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialName.isEmpty ? 'Log food' : 'Edit food',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ---------- TOP: main content ----------
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food name
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Food name',
                          hintText: 'e.g. 150g chicken breast',
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Amount + unit
                      Row(
                        children: [
                          SizedBox(
                            width: 90,
                            child: TextField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Amount',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _unit,
                            items: const [
                              DropdownMenuItem(
                                value: 'g',
                                child: Text('g'),
                              ),
                              DropdownMenuItem(
                                value: 'ml',
                                child: Text('ml'),
                              ),
                              DropdownMenuItem(
                                value: 'serving',
                                child: Text('serving'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() {
                                _unit = v;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Big calories display
                      Row(
                        children: [
                          Text(
                            calories.toString(),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'kcal',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'P ${protein.toStringAsFixed(0)}g • '
                        'C ${carbs.toStringAsFixed(0)}g • '
                        'F ${fat.toStringAsFixed(0)}g • '
                        'Fib ${fiber.toStringAsFixed(0)}g',
                        style: theme.textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 16),

                      // Impact on targets
                      Text(
                        'Impact on your daily targets',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildImpactChip(
                            label: 'kcal',
                            portion: calories.toDouble(),
                            goal: goal?.calories?.toDouble(),
                            color: theme.colorScheme.primary,
                            theme: theme,
                          ),
                          _buildImpactChip(
                            label: 'P',
                            portion: protein,
                            goal: goal?.protein,
                            color: Colors.blueAccent,
                            theme: theme,
                          ),
                          _buildImpactChip(
                            label: 'C',
                            portion: carbs,
                            goal: goal?.carbs,
                            color: Colors.orangeAccent,
                            theme: theme,
                          ),
                          _buildImpactChip(
                            label: 'F',
                            portion: fat,
                            goal: goal?.fat,
                            color: Colors.pinkAccent,
                            theme: theme,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Macro “chips” that are edited by the keypad
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _macroFieldChip(
                            label: 'kcal',
                            controller: _calController,
                            active: _activeField == _ActiveMacroField.calories,
                            onTap: () {
                              setState(() {
                                _activeField = _ActiveMacroField.calories;
                              });
                            },
                          ),
                          _macroFieldChip(
                            label: 'P (g)',
                            controller: _pController,
                            active: _activeField == _ActiveMacroField.protein,
                            onTap: () {
                              setState(() {
                                _activeField = _ActiveMacroField.protein;
                              });
                            },
                          ),
                          _macroFieldChip(
                            label: 'C (g)',
                            controller: _cController,
                            active: _activeField == _ActiveMacroField.carbs,
                            onTap: () {
                              setState(() {
                                _activeField = _ActiveMacroField.carbs;
                              });
                            },
                          ),
                          _macroFieldChip(
                            label: 'F (g)',
                            controller: _fController,
                            active: _activeField == _ActiveMacroField.fat,
                            onTap: () {
                              setState(() {
                                _activeField = _ActiveMacroField.fat;
                              });
                            },
                          ),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: _fibController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                isDense: true,
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
            ),

            // ---------- BOTTOM: keypad + Log button ----------
            Container(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.25),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildKeypad(theme),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final name = _nameController.text.trim();
                        Navigator.of(context).pop({
                          'name': name.isEmpty ? 'Food item' : name,
                          'amount': _parseDouble(_amountController.text),
                          'unit': _unit,
                          'calories': _parseInt(_calController.text),
                          'protein': _parseDouble(_pController.text),
                          'carbs': _parseDouble(_cController.text),
                          'fat': _parseDouble(_fController.text),
                          'fiber': _parseDouble(_fibController.text),
                        });
                      },
                      child: const Text('Log food'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroFieldChip({
    required String label,
    required TextEditingController controller,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.blue.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? Colors.blue : Colors.grey.shade400,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              controller.text.isEmpty ? '—' : controller.text,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(ThemeData theme) {
    final keys = <String>[
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '.', '0', '⌫',
    ];

    return SizedBox(
      height: 220,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: keys.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.4,
        ),
        itemBuilder: (context, index) {
          final key = keys[index];
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => setState(() {
              _onKeyTap(key);
            }),
            child: Text(
              key,
              style: theme.textTheme.titleLarge,
            ),
          );
        },
      ),
    );
  }
}
