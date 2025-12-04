// lib/data.dart
import 'models.dart';

final List<Exercise> defaultExercises = [
  Exercise(
    id: 'bench_press',
    name: 'Barbell Bench Press',
    region: BodyRegion.upper,
    group: MuscleGroup.chest,
    subGroup: 'Mid chest',
  ),
  Exercise(
    id: 'incline_db_press',
    name: 'Incline Dumbbell Press',
    region: BodyRegion.upper,
    group: MuscleGroup.chest,
    subGroup: 'Upper chest',
  ),
  Exercise(
    id: 'ohp',
    name: 'Overhead Press',
    region: BodyRegion.upper,
    group: MuscleGroup.shoulders,
    subGroup: 'Front delts',
  ),
  Exercise(
    id: 'lat_raise',
    name: 'Dumbbell Lateral Raise',
    region: BodyRegion.upper,
    group: MuscleGroup.shoulders,
    subGroup: 'Side delts',
  ),
  Exercise(
    id: 'rear_delt_fly',
    name: 'Rear Delt Fly',
    region: BodyRegion.upper,
    group: MuscleGroup.shoulders,
    subGroup: 'Rear delts',
  ),
  Exercise(
    id: 'pull_up',
    name: 'Pull-up',
    region: BodyRegion.upper,
    group: MuscleGroup.back,
    subGroup: 'Lats',
  ),
  Exercise(
    id: 'bb_row',
    name: 'Barbell Row',
    region: BodyRegion.upper,
    group: MuscleGroup.back,
    subGroup: 'Mid back',
  ),
  Exercise(
    id: 'squat',
    name: 'Barbell Back Squat',
    region: BodyRegion.lower,
    group: MuscleGroup.legs,
    subGroup: 'Quads/Glutes',
  ),
  Exercise(
    id: 'rdl',
    name: 'Romanian Deadlift',
    region: BodyRegion.lower,
    group: MuscleGroup.legs,
    subGroup: 'Hamstrings/Glutes',
  ),
  Exercise(
    id: 'bb_curl',
    name: 'Barbell Curl',
    region: BodyRegion.upper,
    group: MuscleGroup.arms,
    subGroup: 'Biceps',
  ),
  Exercise(
    id: 'tricep_pushdown',
    name: 'Cable Tricep Pushdown',
    region: BodyRegion.upper,
    group: MuscleGroup.arms,
    subGroup: 'Triceps',
  ),
];
