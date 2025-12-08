// lib/data.dart

import 'models.dart';

/// Default exercises, each targeting a specific primary muscle.
final List<Exercise> defaultExercises = [
  // --- CHEST ---
  Exercise(
    id: 'bench_barbell_flat',
    name: 'Barbell Bench Press',
    region: BodyRegion.upper,
    group: MuscleGroup.midChest,
    subGroup: 'Pecs',
  ),
  Exercise(
    id: 'incline_dumbbell_press',
    name: 'Incline Dumbbell Press',
    region: BodyRegion.upper,
    group: MuscleGroup.upperChest,
    subGroup: 'Pecs',
  ),
  Exercise(
    id: 'decline_barbell_press',
    name: 'Decline Barbell Press',
    region: BodyRegion.upper,
    group: MuscleGroup.lowerChest,
    subGroup: 'Pecs',
  ),

  // --- BACK ---
  Exercise(
    id: 'lat_pulldown',
    name: 'Lat Pulldown',
    region: BodyRegion.upper,
    group: MuscleGroup.lats,
    subGroup: 'Lats',
  ),
  Exercise(
    id: 'seated_cable_row',
    name: 'Seated Cable Row',
    region: BodyRegion.upper,
    group: MuscleGroup.midBack,
    subGroup: 'Mid back',
  ),
  Exercise(
    id: 'barbell_row',
    name: 'Barbell Row',
    region: BodyRegion.upper,
    group: MuscleGroup.upperBack,
    subGroup: 'Upper / mid back',
  ),

  // --- SHOULDERS ---
  Exercise(
    id: 'ohp_barbell',
    name: 'Overhead Barbell Press',
    region: BodyRegion.upper,
    group: MuscleGroup.frontDelts,
    subGroup: 'Front delts',
  ),
  Exercise(
    id: 'lateral_raise',
    name: 'Dumbbell Lateral Raise',
    region: BodyRegion.upper,
    group: MuscleGroup.sideDelts,
    subGroup: 'Side delts',
  ),
  Exercise(
    id: 'rear_delt_fly',
    name: 'Rear Delt Fly',
    region: BodyRegion.upper,
    group: MuscleGroup.rearDelts,
    subGroup: 'Rear delts',
  ),

  // --- ARMS ---
  Exercise(
    id: 'barbell_curl',
    name: 'Barbell Curl',
    region: BodyRegion.upper,
    group: MuscleGroup.biceps,
    subGroup: 'Biceps',
  ),
  Exercise(
    id: 'tricep_pushdown',
    name: 'Tricep Pushdown',
    region: BodyRegion.upper,
    group: MuscleGroup.triceps,
    subGroup: 'Triceps',
  ),
  Exercise(
    id: 'hammer_curl',
    name: 'Hammer Curl',
    region: BodyRegion.upper,
    group: MuscleGroup.forearms,
    subGroup: 'Forearms / brachialis',
  ),

  // --- CORE ---
  Exercise(
    id: 'crunch',
    name: 'Crunches',
    region: BodyRegion.full,
    group: MuscleGroup.upperAbs,
    subGroup: 'Upper abs',
  ),
  Exercise(
    id: 'leg_raise',
    name: 'Hanging Leg Raise',
    region: BodyRegion.full,
    group: MuscleGroup.lowerAbs,
    subGroup: 'Lower abs',
  ),
  Exercise(
    id: 'side_plank',
    name: 'Side Plank',
    region: BodyRegion.full,
    group: MuscleGroup.obliques,
    subGroup: 'Obliques',
  ),

  // --- LOWER BODY ---
  Exercise(
    id: 'squat_barbell',
    name: 'Barbell Squat',
    region: BodyRegion.lower,
    group: MuscleGroup.quads,
    subGroup: 'Quads / glutes',
  ),
  Exercise(
    id: 'romanian_deadlift',
    name: 'Romanian Deadlift',
    region: BodyRegion.lower,
    group: MuscleGroup.hamstrings,
    subGroup: 'Hamstrings',
  ),
  Exercise(
    id: 'hip_thrust',
    name: 'Barbell Hip Thrust',
    region: BodyRegion.lower,
    group: MuscleGroup.glutes,
    subGroup: 'Glutes',
  ),
  Exercise(
    id: 'calf_raise',
    name: 'Standing Calf Raise',
    region: BodyRegion.lower,
    group: MuscleGroup.calves,
    subGroup: 'Calves',
  ),
];
