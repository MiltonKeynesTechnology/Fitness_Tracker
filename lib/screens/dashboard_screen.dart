// lib/screens/dashboard_screen.dart

import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';

import '../models.dart';

class DashboardScreen extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final List<WeightEntry> weightEntries;
  final List<MealEntry> meals;
  final void Function(WeightEntry) onAddWeight;
  final VoidCallback onOpenFitness;
  final VoidCallback onOpenNutrition;

  // NEW: profile + schedule
  final Set<int> weighInWeekdays;
  final String userName;
  final double? userHeightCm;
  final String? avatarPath;
  final VoidCallback onOpenProfile;

  const DashboardScreen({
    super.key,
    required this.sessions,
    required this.weightEntries,
    required this.meals,
    required this.onAddWeight,
    required this.onOpenFitness,
    required this.onOpenNutrition,
    required this.weighInWeekdays,
    required this.userName,
    required this.userHeightCm,
    required this.avatarPath,
    required this.onOpenProfile,
  });

  List<WorkoutSession> get _completedSessions {
    try {
      return sessions
          .where((s) => s.status == WorkoutStatus.completed)
          .toList();
    } catch (_) {
      return sessions;
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  WeightEntry? get _latestWeight {
    if (weightEntries.isEmpty) return null;
    return weightEntries.last;
  }

  double? get _weightChangeLast30Days {
    if (weightEntries.length < 2) return null;
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 30));

    final recent = weightEntries
        .where((w) => w.date.isAfter(cutoff))
        .toList();
    if (recent.length < 2) return null;

    final first = recent.first;
    final last = recent.last;
    return last.weightKg - first.weightKg;
  }

  Future<void> _showAddWeightDialog(BuildContext context) async {
    final latest = _latestWeight;
    final controller = TextEditingController(
      text: latest?.weightKg.toStringAsFixed(1) ?? '',
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit today\'s weight'),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            hintText: 'e.g. 74.5',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) {
                Navigator.of(ctx).pop();
                return;
              }
              final value = double.tryParse(text.replaceAll(',', '.'));
              if (value == null) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number.'),
                  ),
                );
                return;
              }
              Navigator.of(ctx).pop(value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    final today = DateTime.now();
    final entry = WeightEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: today,
      weightKg: result,
    );
    onAddWeight(entry);
  }

  String _weekdayShort(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final completed = _completedSessions;

    final weekWorkouts = completed
        .where((s) => s.date.isAfter(weekAgo))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalThisWeek = weekWorkouts.length;

    WorkoutSession? lastWorkout;
    if (completed.isNotEmpty) {
      completed.sort((a, b) => b.date.compareTo(a.date));
      lastWorkout = completed.first;
    }

    int _totalSetsThisWeek() {
      return weekWorkouts.fold<int>(
        0,
        (sum, s) =>
            sum +
            s.exercises.fold<int>(
              0,
              (sumEx, we) => sumEx + we.sets.length,
            ),
      );
    }

    final totalSetsWeek = _totalSetsThisWeek();
    final latestWeight = _latestWeight;
    final weightDelta30 = _weightChangeLast30Days;

    // Nutrition: today summary
    final todaysMeals = meals.where((m) =>
        m.dateTime.year == now.year &&
        m.dateTime.month == now.month &&
        m.dateTime.day == now.day);
    final mealsTodayCount = todaysMeals.length;
    final caloriesToday = todaysMeals.fold<int>(
      0,
      (sum, m) => sum + (m.calories ?? 0),
    );

    // weigh-in helpers
    final bool todayIsWeighDay = weighInWeekdays.contains(now.weekday);

    // BMI
    double? bmi;
    if (latestWeight != null && userHeightCm != null && userHeightCm! > 0) {
      final hM = userHeightCm! / 100.0;
      bmi = latestWeight.weightKg / math.pow(hM, 2);
    }

    // PROFILE CARD
    Widget buildProfileCard() {
      final displayName =
          userName.trim().isEmpty ? 'Friend' : userName.trim();

      ImageProvider? avatarImage;
      if (avatarPath != null && avatarPath!.isNotEmpty) {
        avatarImage = FileImage(File(avatarPath!));
      }

      return InkWell(
        onTap: onOpenProfile,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // top banner
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Welcome, $displayName',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Text(
                              displayName.isEmpty
                                  ? 'U'
                                  : displayName.characters.first
                                      .toUpperCase(),
                              style: theme.textTheme.titleLarge,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userHeightCm == null
                                ? 'Height: –'
                                : 'Height: ${userHeightCm!.toStringAsFixed(0)} cm',
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (latestWeight != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Latest: ${latestWeight.weightKg.toStringAsFixed(1)} kg',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                          if (bmi != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'BMI: ${bmi.toStringAsFixed(1)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ],
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

    Widget buildWeighScheduleDots() {
      const weekdayOrder = [
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
        DateTime.sunday,
      ];
      const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(7, (i) {
          final day = weekdayOrder[i];
          final active = weighInWeekdays.contains(day);
          final isToday = now.weekday == day;

          final bgColor = active
              ? (isToday
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondaryContainer)
              : Colors.transparent;

          final borderColor = active
              ? (isToday
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondaryContainer)
              : theme.colorScheme.outlineVariant;

          final textColor = active
              ? theme.colorScheme.onSecondaryContainer
              : theme.textTheme.labelSmall?.color?.withOpacity(0.6);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  labels[i],
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
              ],
            ),
          );
        }),
      );
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PROFILE TILE
          buildProfileCard(),
          const SizedBox(height: 16),

          Text(
            'Overview',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          // BODYWEIGHT CARD
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.monitor_weight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Bodyweight',
                              style: theme.textTheme.titleMedium,
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () =>
                                  _showAddWeightDialog(context),
                              icon: const Icon(
                                Icons.add,
                                size: 18,
                              ),
                              label: const Text('Log'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (todayIsWeighDay)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Weigh-in day',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme
                                        .colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: buildWeighScheduleDots(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (latestWeight == null)
                          const Text(
                            'No bodyweight logged yet. Tap "Log" to add your first entry.',
                          )
                        else ...[
                          Text(
                            '${latestWeight.weightKg.toStringAsFixed(1)} kg',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Last entry: ${_formatDate(latestWeight.date)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (weightDelta30 != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Change (last 30 days): '
                              '${weightDelta30 >= 0 ? '+' : ''}'
                              '${weightDelta30.toStringAsFixed(1)} kg',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // FITNESS CARD
          InkWell(
            onTap: onOpenFitness,
            borderRadius: BorderRadius.circular(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fitness_center),
                        const SizedBox(width: 8),
                        Text(
                          'Fitness',
                          style: theme.textTheme.titleMedium,
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (sessions.isEmpty)
                      const Text(
                        'No workouts logged yet. Tap to go to the Fitness section '
                        'and add your first session.',
                      )
                    else ...[
                      Text(
                        '$totalThisWeek workout${totalThisWeek == 1 ? '' : 's'} in the last 7 days',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (totalSetsWeek > 0)
                        Text(
                          '$totalSetsWeek sets logged this week',
                          style: theme.textTheme.bodySmall,
                        ),
                      const SizedBox(height: 8),
                      if (lastWorkout != null) ...[
                        Text(
                          'Last workout:',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${lastWorkout.name} on ${_formatDate(lastWorkout.date)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Tap to jump into the Fitness view (Today, History, Exercises, Stats).',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // NUTRITION CARD
          InkWell(
            onTap: onOpenNutrition,
            borderRadius: BorderRadius.circular(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.restaurant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Nutrition',
                                style: theme.textTheme.titleMedium,
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (mealsTodayCount == 0)
                            const Text(
                              'No meals logged today. Tap to go to the Nutrition section '
                              'and add what you ate.',
                            )
                          else ...[
                            Text(
                              '$mealsTodayCount meal${mealsTodayCount == 1 ? '' : 's'} logged today',
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (caloriesToday > 0)
                              Text(
                                '$caloriesToday kcal (total for today)',
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Later this will show ingredients, symptoms and correlations '
                            'for intolerances.',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // HEALTH PLACEHOLDER
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.health_and_safety),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Health & Intolerances (coming soon)',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'ll be able to log how you feel after meals, '
                          'track symptoms over time, and see potential '
                          'patterns between specific ingredients and discomfort.',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This module will focus on patterns and hints, '
                          'not medical diagnosis.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
