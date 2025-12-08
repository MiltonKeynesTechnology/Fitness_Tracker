// lib/models.dart

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

/// Detailed muscles. Each exercise has ONE primary muscle,
/// but can also have multiple secondary muscles.
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

/// Planned vs completed workouts.
enum WorkoutStatus {
  planned,
  completed,
}

String workoutStatusLabel(WorkoutStatus s) {
  switch (s) {
    case WorkoutStatus.planned:
      return 'Planned';
    case WorkoutStatus.completed:
      return 'Completed';
  }
}

/// One exercise definition.
class Exercise {
  final String id;
  final String name;
  final BodyRegion region;

  /// Primary muscle group this exercise targets.
  final MuscleGroup group;

  /// Optional extra muscles this exercise hits (e.g. biceps on lat pulldown).
  final List<MuscleGroup> secondary;

  /// Extra info if you want (e.g. "Incline", "Cable", "Neutral grip").
  final String? subGroup;

  /// Optional performance goals / PR info.
  final double? goalWeight;
  final int? goalReps;
  final double? manualPr; // manual PR weight

  Exercise({
    required this.id,
    required this.name,
    required this.region,
    required this.group,
    List<MuscleGroup>? secondary,
    this.subGroup,
    this.goalWeight,
    this.goalReps,
    this.manualPr,
  }) : secondary = secondary ?? [];

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
      secondary: secondary ?? List<MuscleGroup>.from(this.secondary),
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
      // store secondary muscles as list of enum indices
      'secondary': secondary.map((m) => m.index).toList(),
      'subGroup': subGroup,
      'goalWeight': goalWeight,
      'goalReps': goalReps,
      'manualPr': manualPr,
    };
  }

  factory Exercise.fromMap(Map map) {
    // Backwards compatible: older data won't have 'secondary'
    List<MuscleGroup> secondary = [];
    final rawSecondary = map['secondary'];
    if (rawSecondary is List) {
      secondary = rawSecondary
          .whereType<int>()
          .where((i) => i >= 0 && i < MuscleGroup.values.length)
          .map((i) => MuscleGroup.values[i])
          .toList();
    }

    return Exercise(
      id: map['id'] as String,
      name: map['name'] as String,
      region: BodyRegion.values[map['region'] as int],
      group: MuscleGroup.values[map['group'] as int],
      secondary: secondary,
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

  /// Planned workouts vs completed.
  WorkoutStatus status;

  WorkoutSession({
    required this.id,
    required this.name,
    required this.date,
    required this.exercises,
    WorkoutStatus? status,
  }) : status = status ?? WorkoutStatus.completed;

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
    final statusIndex = map['status'] as int?;
    WorkoutStatus status;
    if (statusIndex == null ||
        statusIndex < 0 ||
        statusIndex >= WorkoutStatus.values.length) {
      status = WorkoutStatus.completed; // default for old data
    } else {
      status = WorkoutStatus.values[statusIndex];
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
