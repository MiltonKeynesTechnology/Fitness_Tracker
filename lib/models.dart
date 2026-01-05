// lib/models.dart

import 'package:flutter/foundation.dart';

/// High-level body region (for splits etc.)
enum BodyRegion {
  upper,
  lower,
  full,
}

String bodyRegionLabel(BodyRegion r) {
  switch (r) {
    case BodyRegion.upper:
      return 'Upper body';
    case BodyRegion.lower:
      return 'Lower body';
    case BodyRegion.full:
      return 'Full body';
  }
}

/// Detailed muscles.
enum MuscleGroup {
  // Chest
  upperChest,
  midChest,
  lowerChest,

  // Back
  lats,
  upperBack,
  midBack,
  lowerBack,

  // Shoulders
  frontDelts,
  sideDelts,
  rearDelts,

  // Arms
  biceps,
  triceps,
  forearms,

  // Core
  upperAbs,
  lowerAbs,
  obliques,
  spinalErectors,

  // Lower body
  glutes,
  quads,
  hamstrings,
  calves,
}

String muscleGroupLabel(MuscleGroup g) {
  switch (g) {
    case MuscleGroup.upperChest:
      return 'Upper chest';
    case MuscleGroup.midChest:
      return 'Mid chest';
    case MuscleGroup.lowerChest:
      return 'Lower chest';

    case MuscleGroup.lats:
      return 'Lats';
    case MuscleGroup.upperBack:
      return 'Upper back';
    case MuscleGroup.midBack:
      return 'Mid back';
    case MuscleGroup.lowerBack:
      return 'Lower back';

    case MuscleGroup.frontDelts:
      return 'Front delts';
    case MuscleGroup.sideDelts:
      return 'Side delts';
    case MuscleGroup.rearDelts:
      return 'Rear delts';

    case MuscleGroup.biceps:
      return 'Biceps';
    case MuscleGroup.triceps:
      return 'Triceps';
    case MuscleGroup.forearms:
      return 'Forearms';

    case MuscleGroup.upperAbs:
      return 'Upper abs';
    case MuscleGroup.lowerAbs:
      return 'Lower abs';
    case MuscleGroup.obliques:
      return 'Obliques';
    case MuscleGroup.spinalErectors:
      return 'Spinal erectors';

    case MuscleGroup.glutes:
      return 'Glutes';
    case MuscleGroup.quads:
      return 'Quads';
    case MuscleGroup.hamstrings:
      return 'Hamstrings';
    case MuscleGroup.calves:
      return 'Calves';
  }
}

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
  other,
}

String mealTypeLabel(MealType type) {
  switch (type) {
    case MealType.breakfast:
      return 'Breakfast';
    case MealType.lunch:
      return 'Lunch';
    case MealType.dinner:
      return 'Dinner';
    case MealType.snack:
      return 'Snack';
    case MealType.other:
      return 'Other';
  }
}

/// Workout status: planned vs completed.
enum WorkoutStatus {
  planned,
  completed,
}

String workoutStatusLabel(WorkoutStatus status) {
  switch (status) {
    case WorkoutStatus.planned:
      return 'Planned';
    case WorkoutStatus.completed:
      return 'Completed';
  }
}

/// One exercise definition (supports primary + secondary muscles).
class Exercise {
  final String id;
  final String name;
  final BodyRegion region;

  /// Primary muscle group.
  final MuscleGroup group;

  /// Secondary muscles (optional, can be empty).
  final List<MuscleGroup> secondary;

  /// Optional extra descriptor (e.g. “close grip”, “incline”).
  final String? subGroup;

  /// Goal weight and reps for this exercise.
  final double? goalWeight;
  final int? goalReps;

  /// Manually entered PR if you didn’t log from day 1.
  final double? manualPr;

  Exercise({
    required this.id,
    required this.name,
    required this.region,
    required this.group,
    this.secondary = const [],
    this.subGroup,
    this.goalWeight,
    this.goalReps,
    this.manualPr,
  });

  Exercise copyWith({
    String? id,
    String? name,
    BodyRegion? region,
    MuscleGroup? group,
    List<MuscleGroup>? secondary,
    String? subGroup,
    double? goalWeight,
    int? goalReps,
    double? manualPr,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      region: region ?? this.region,
      group: group ?? this.group,
      secondary: secondary ?? this.secondary,
      subGroup: subGroup ?? this.subGroup,
      goalWeight: goalWeight ?? this.goalWeight,
      goalReps: goalReps ?? this.goalReps,
      manualPr: manualPr ?? this.manualPr,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'region': region.index,
      'group': group.index,
      // store secondary as a list of enum indices
      'secondary': secondary.map((m) => m.index).toList(),
      'subGroup': subGroup,
      'goalWeight': goalWeight,
      'goalReps': goalReps,
      'manualPr': manualPr,
    };
  }

  factory Exercise.fromMap(Map map) {
    // Backwards-compatible: older data may not have "secondary"
    final rawSecondary = map['secondary'];
    List<MuscleGroup> secondaryGroups = const [];

    if (rawSecondary is List) {
      secondaryGroups = rawSecondary
          .whereType<int>()
          .map((i) {
            final idx =
                i.clamp(0, MuscleGroup.values.length - 1);
            return MuscleGroup.values[idx];
          })
          .toList();
    }

    return Exercise(
      id: map['id'] as String,
      name: map['name'] as String,
      region: BodyRegion.values[map['region'] as int],
      group: MuscleGroup.values[map['group'] as int],
      secondary: secondaryGroups,
      subGroup: map['subGroup'] as String?,
      goalWeight: (map['goalWeight'] as num?)?.toDouble(),
      goalReps: map['goalReps'] as int?,
      manualPr: (map['manualPr'] as num?)?.toDouble(),
    );
  }
}

/// A single set in a workout.
class ExerciseSet {
  int reps;
  double? weight; // null for pure bodyweight

  ExerciseSet({
    required this.reps,
    this.weight,
  });

  Map<String, dynamic> toMap() {
    return {
      'reps': reps,
      'weight': weight,
    };
  }

  factory ExerciseSet.fromMap(Map map) {
    return ExerciseSet(
      reps: map['reps'] as int,
      weight: (map['weight'] as num?)?.toDouble(),
    );
  }
}

/// An exercise performed within a session, with its sets.
class WorkoutExercise {
  final String id;
  final Exercise exercise;
  final List<ExerciseSet> sets;

  WorkoutExercise({
    required this.id,
    required this.exercise,
    required this.sets,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise': exercise.toMap(),
      'sets': sets.map((s) => s.toMap()).toList(),
    };
  }

  factory WorkoutExercise.fromMap(Map map) {
    return WorkoutExercise(
      id: map['id'] as String,
      exercise: Exercise.fromMap(map['exercise'] as Map),
      sets: (map['sets'] as List)
          .map((s) => ExerciseSet.fromMap(s as Map))
          .toList(),
    );
  }
}

/// A training session (workout day).
class WorkoutSession {
  final String id;
  String name;
  DateTime date;
  final List<WorkoutExercise> exercises;
  WorkoutStatus status;

  WorkoutSession({
    required this.id,
    required this.name,
    required this.date,
    required this.exercises,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'status': status.index,
    };
  }

  factory WorkoutSession.fromMap(Map map) {
    final rawStatus = map['status'] as int?;
    WorkoutStatus status;
    if (rawStatus == null) {
      status = WorkoutStatus.completed; // old data default
    } else {
      final idx =
          rawStatus.clamp(0, WorkoutStatus.values.length - 1);
      status = WorkoutStatus.values[idx];
    }

    return WorkoutSession(
      id: map['id'] as String,
      name: map['name'] as String,
      date: DateTime.parse(map['date'] as String),
      exercises: (map['exercises'] as List)
          .map((e) => WorkoutExercise.fromMap(e as Map))
          .toList(),
      status: status,
    );
  }
}

/// Logged bodyweight entry (kg).
class WeightEntry {
  final String id;
  final DateTime date;
  final double weightKg;

  WeightEntry({
    required this.id,
    required this.date,
    required this.weightKg,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weightKg': weightKg,
    };
  }

  factory WeightEntry.fromMap(Map map) {
    return WeightEntry(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      weightKg: (map['weightKg'] as num).toDouble(),
    );
  }
}

/// A single food item inside a meal (for breakdown).
class MealComponent {
  final String name;
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;

  MealComponent({
    required this.name,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
    };
  }

  factory MealComponent.fromMap(Map map) {
    return MealComponent(
      name: map['name'] as String,
      calories: map['calories'] as int?,
      protein: (map['protein'] as num?)?.toDouble(),
      carbs: (map['carbs'] as num?)?.toDouble(),
      fat: (map['fat'] as num?)?.toDouble(),
      fiber: (map['fiber'] as num?)?.toDouble(),
    );
  }
}

/// Logged meal (macro snapshot, plus optional breakdown into items).
class MealEntry {
  final String id;
  final DateTime dateTime;
  final String title;
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;
  final String? notes;
  final List<MealComponent> items;

  /// NEW: explicit meal type (Breakfast/Lunch/Dinner/Snack/Other)
  final MealType? mealType;

  MealEntry({
    required this.id,
    required this.dateTime,
    required this.title,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.notes,
    this.items = const [],
    this.mealType, // <--- add this
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'title': title,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'notes': notes,
      'items': items.map((i) => i.toMap()).toList(),
      // NEW: store enum as string
      'mealType': mealType?.name,
    };
  }

  factory MealEntry.fromMap(Map map) {
    MealType? _parseMealType(dynamic value) {
      if (value is String) {
        switch (value) {
          case 'breakfast':
            return MealType.breakfast;
          case 'lunch':
            return MealType.lunch;
          case 'dinner':
            return MealType.dinner;
          case 'snack':
            return MealType.snack;
          case 'other':
            return MealType.other;
        }
      }
      return null;
    }

    return MealEntry(
      id: map['id'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      title: map['title'] as String,
      calories: map['calories'] as int?,
      protein: (map['protein'] as num?)?.toDouble(),
      carbs: (map['carbs'] as num?)?.toDouble(),
      fat: (map['fat'] as num?)?.toDouble(),
      fiber: (map['fiber'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      items: (map['items'] as List? ?? [])
          .map((m) => MealComponent.fromMap(m as Map))
          .toList(),
      mealType: _parseMealType(map['mealType']),
    );
  }
}

// One NutritionGoal per weekday (1 = Monday ... 7 = Sunday).
class WeeklyNutritionGoals {
  /// Map from weekday (1 = Monday ... 7 = Sunday) to a goal (or null = no goal).
  final Map<int, NutritionGoal?> byWeekday;

  WeeklyNutritionGoals({Map<int, NutritionGoal?>? byWeekday})
      : byWeekday = byWeekday ?? {};

  /// Returns the goal for [date], falling back to [fallback] if none is set.
  NutritionGoal? forDate(DateTime date, {NutritionGoal? fallback}) {
    return byWeekday[date.weekday] ?? fallback;
  }

  WeeklyNutritionGoals copyWith({Map<int, NutritionGoal?>? byWeekday}) {
    return WeeklyNutritionGoals(
      byWeekday: byWeekday ?? this.byWeekday,
    );
  }

  /// Convert to a plain Map for Hive.
  Map<String, dynamic> toMap() {
    return {
      'byWeekday': byWeekday.map((key, value) {
        return MapEntry(
          key.toString(),        // e.g. "1".."7"
          value?.toMap(),        // NutritionGoal? -> Map?
        );
      }),
    };
  }

  /// Restore from a Map read from Hive.
  factory WeeklyNutritionGoals.fromMap(Map map) {
    final raw = map['byWeekday'] as Map?;
    if (raw == null) return WeeklyNutritionGoals();

    final converted = <int, NutritionGoal?>{};
    raw.forEach((key, value) {
      final weekday = int.tryParse(key.toString());
      if (weekday == null) return;
      if (value == null) {
        converted[weekday] = null;
      } else {
        converted[weekday] = NutritionGoal.fromMap(value as Map);
      }
    });

    return WeeklyNutritionGoals(byWeekday: converted);
  }
}



/// Daily nutrition goal (very lightweight).
class NutritionGoal {
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;

  NutritionGoal({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
  });

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
    };
  }

  factory NutritionGoal.fromMap(Map map) {
    return NutritionGoal(
      calories: map['calories'] as int?,
      protein: (map['protein'] as num?)?.toDouble(),
      carbs: (map['carbs'] as num?)?.toDouble(),
      fat: (map['fat'] as num?)?.toDouble(),
      fiber: (map['fiber'] as num?)?.toDouble(),
    );
  }
}

/// Types of supplements (for tracking).
enum SupplementCategory {
  protein,
  creatine,
  preWorkout,
  stimulant,
  vitamin,
  omega3,
  health,
  other,
}

String supplementCategoryLabel(SupplementCategory c) {
  switch (c) {
    case SupplementCategory.protein:
      return 'Protein';
    case SupplementCategory.creatine:
      return 'Creatine';
    case SupplementCategory.preWorkout:
      return 'Pre-workout';
    case SupplementCategory.stimulant:
      return 'Stimulant';
    case SupplementCategory.vitamin:
      return 'Vitamin';
    case SupplementCategory.omega3:
      return 'Omega-3';
    case SupplementCategory.health:
      return 'Health';
    case SupplementCategory.other:
      return 'Other';
  }
}

class CookbookMeal {
  final String id;
  final String title;
  final MealType mealType;
  final List<MealComponent> items;

  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;

  CookbookMeal({
    required this.id,
    required this.title,
    required this.mealType,
    required this.items,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'mealType': mealType.index,
      'items': items.map((m) => m.toMap()).toList(),
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
    };
  }

  factory CookbookMeal.fromMap(Map map) {
    return CookbookMeal(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      mealType: MealType.values[
          map['mealType'] as int? ?? MealType.other.index],
      items: (map['items'] as List? ?? [])
          .map((m) => MealComponent.fromMap(m as Map))
          .toList(),
      calories: map['calories'] as int?,
      protein: (map['protein'] as num?)?.toDouble(),
      carbs: (map['carbs'] as num?)?.toDouble(),
      fat: (map['fat'] as num?)?.toDouble(),
      fiber: (map['fiber'] as num?)?.toDouble(),
    );
  }
}


/// A logged supplement intake.
class SupplementEntry {
  final String id;
  final DateTime dateTime;
  final String name; // e.g. "Whey isolate", "Creatine monohydrate"
  final SupplementCategory category;
  final double? dose; // numeric dose (e.g. 5)
  final String? unit; // e.g. "g", "mg", "caps"
  final String? notes; // e.g. "pre-workout", "before bed"

  SupplementEntry({
    required this.id,
    required this.dateTime,
    required this.name,
    required this.category,
    this.dose,
    this.unit,
    this.notes,
  });

  SupplementEntry copyWith({
    String? id,
    DateTime? dateTime,
    String? name,
    SupplementCategory? category,
    double? dose,
    String? unit,
    String? notes,
  }) {
    return SupplementEntry(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      name: name ?? this.name,
      category: category ?? this.category,
      dose: dose ?? this.dose,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'name': name,
      'category': category.index,
      'dose': dose,
      'unit': unit,
      'notes': notes,
    };
  }

  factory SupplementEntry.fromMap(Map map) {
    return SupplementEntry(
      id: map['id'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      name: map['name'] as String,
      category:
          SupplementCategory.values[map['category'] as int],
      dose: (map['dose'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      notes: map['notes'] as String?,
    );
  }
}

class DailyEnergyEntry {
  final DateTime date;     // date only (no time)
  final int burnedKcal;

  DailyEnergyEntry({
    required this.date,
    required this.burnedKcal,
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'burnedKcal': burnedKcal,
      };

  factory DailyEnergyEntry.fromMap(Map map) {
    return DailyEnergyEntry(
      date: DateTime.parse(map['date'] as String),
      burnedKcal: map['burnedKcal'] as int,
    );
  }
}
