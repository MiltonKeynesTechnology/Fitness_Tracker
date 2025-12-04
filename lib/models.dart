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

/// Detailed muscles. Each exercise targets ONE primary muscle.
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

/// One exercise definition.
class Exercise {
  final String id;
  final String name;
  final BodyRegion region;
  final MuscleGroup group; // primary muscle
  final String? subGroup;  // extra info if you want

  final double? goalWeight;
  final int? goalReps;
  final double? manualPr; // manual PR weight

  Exercise({
    required this.id,
    required this.name,
    required this.region,
    required this.group,
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
      'subGroup': subGroup,
      'goalWeight': goalWeight,
      'goalReps': goalReps,
      'manualPr': manualPr,
    };
  }

  factory Exercise.fromMap(Map map) {
    return Exercise(
      id: map['id'] as String,
      name: map['name'] as String,
      region: BodyRegion.values[map['region'] as int],
      group: MuscleGroup.values[map['group'] as int],
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

  WorkoutSession({
    required this.id,
    required this.name,
    required this.date,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory WorkoutSession.fromMap(Map map) {
    return WorkoutSession(
      id: map['id'] as String,
      name: map['name'] as String,
      date: DateTime.parse(map['date'] as String),
      exercises: (map['exercises'] as List)
          .map((e) => WorkoutExercise.fromMap(e as Map))
          .toList(),
    );
  }
}
