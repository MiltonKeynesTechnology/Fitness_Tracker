// lib/models.dart

enum BodyRegion { upper, lower, full, core, other }

enum MuscleGroup {
  chest,
  back,
  shoulders,
  legs,
  arms,
  glutes,
  calves,
  core,
}

class Exercise {
  final String id;
  final String name;
  final BodyRegion region;
  final MuscleGroup group;
  final String? subGroup; // e.g. "Rear delts", "Quads"

  const Exercise({
    required this.id,
    required this.name,
    required this.region,
    required this.group,
    this.subGroup,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'region': region.index,
        'group': group.index,
        'subGroup': subGroup,
      };

  factory Exercise.fromMap(Map map) => Exercise(
        id: map['id'] as String,
        name: map['name'] as String,
        region: BodyRegion.values[map['region'] as int],
        group: MuscleGroup.values[map['group'] as int],
        subGroup: map['subGroup'] as String?,
      );
}

class WorkoutSet {
  final int reps;
  final double? weight; // kg, can be null for bodyweight

  const WorkoutSet({
    required this.reps,
    this.weight,
  });

  Map<String, dynamic> toMap() => {
        'reps': reps,
        'weight': weight,
      };

  factory WorkoutSet.fromMap(Map map) => WorkoutSet(
        reps: map['reps'] as int,
        weight: (map['weight'] as num?)?.toDouble(),
      );
}

class WorkoutExercise {
  final Exercise exercise;
  final List<WorkoutSet> sets;

  WorkoutExercise({
    required this.exercise,
    List<WorkoutSet>? sets,
  }) : sets = sets ?? [];

  Map<String, dynamic> toMap() => {
        'exercise': exercise.toMap(),
        'sets': sets.map((s) => s.toMap()).toList(),
      };

  factory WorkoutExercise.fromMap(Map map) => WorkoutExercise(
        exercise: Exercise.fromMap(map['exercise'] as Map),
        sets: (map['sets'] as List)
            .map((m) => WorkoutSet.fromMap(m as Map))
            .toList(),
      );
}

class WorkoutSession {
  final String id;
  final DateTime date;
  String name; // editable
  final List<WorkoutExercise> exercises;

  WorkoutSession({
    required this.id,
    required this.date,
    required this.name,
    List<WorkoutExercise>? exercises,
  }) : exercises = exercises ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'name': name,
        'exercises': exercises.map((we) => we.toMap()).toList(),
      };

  factory WorkoutSession.fromMap(Map map) => WorkoutSession(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        name: map['name'] as String,
        exercises: (map['exercises'] as List)
            .map((m) => WorkoutExercise.fromMap(m as Map))
            .toList(),
      );
}

// --- Helper label functions for UI ---

String muscleGroupLabel(MuscleGroup g) {
  switch (g) {
    case MuscleGroup.chest:
      return 'Chest';
    case MuscleGroup.back:
      return 'Back';
    case MuscleGroup.shoulders:
      return 'Shoulders';
    case MuscleGroup.legs:
      return 'Legs';
    case MuscleGroup.arms:
      return 'Arms';
    case MuscleGroup.glutes:
      return 'Glutes';
    case MuscleGroup.calves:
      return 'Calves';
    case MuscleGroup.core:
      return 'Core';
  }
}

String bodyRegionLabel(BodyRegion r) {
  switch (r) {
    case BodyRegion.upper:
      return 'Upper Body';
    case BodyRegion.lower:
      return 'Lower Body';
    case BodyRegion.full:
      return 'Full Body';
    case BodyRegion.core:
      return 'Core';
    case BodyRegion.other:
      return 'Other';
  }
}
