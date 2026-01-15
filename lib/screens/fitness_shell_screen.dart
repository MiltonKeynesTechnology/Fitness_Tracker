// lib/screens/fitness_shell_screen.dart

import 'package:flutter/material.dart';

import '../models.dart';
import 'today_screen.dart';
import 'history_screen.dart';
import 'exercises_screen.dart';
import 'stats_screen.dart';

class FitnessShellScreen extends StatefulWidget {
  final List<Exercise> exercises;
  final List<WorkoutSession> sessions;

  final void Function(WorkoutSession) onAddSession;
  final void Function(Exercise) onAddExercise;
  final VoidCallback onSessionsChanged;
  final void Function(WorkoutSession) onDeleteSession;
  final void Function(Exercise) onUpdateExercise;
  final Future<void> Function() onClearAll;

  final List<CookbookMeal> cookbookMeals;
  final WeeklyNutritionGoals weeklyGoals;
  final void Function(WeeklyNutritionGoals) onUpdateWeeklyGoals;

  final WeeklyPlanExtras weeklyPlanExtras;
  final void Function(WeeklyPlanExtras) onUpdateWeeklyPlanExtras;

  // For nutrition-aware stats
  final List<MealEntry> meals;
  final NutritionGoal? nutritionGoal;

  const FitnessShellScreen({
    super.key,
    required this.exercises,
    required this.sessions,
    required this.onAddSession,
    required this.onAddExercise,
    required this.onSessionsChanged,
    required this.onDeleteSession,
    required this.onUpdateExercise,
    required this.onClearAll,
    required this.meals,
    required this.nutritionGoal,

    required this.cookbookMeals,
    required this.weeklyGoals,
    required this.onUpdateWeeklyGoals,
    required this.weeklyPlanExtras,
    required this.onUpdateWeeklyPlanExtras,
  });

  @override
  State<FitnessShellScreen> createState() => _FitnessShellScreenState();
}

class _FitnessShellScreenState extends State<FitnessShellScreen> {
  int _selectedIndex = 0;

  void _onInnerNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayScreen(
        exercises: widget.exercises,
        onSaveSession: widget.onAddSession,
        onAddExercise: widget.onAddExercise,
      ),
      HistoryScreen(
        sessions: widget.sessions,
        exercises: widget.exercises,
        onSessionsChanged: widget.onSessionsChanged,
        onAddExercise: widget.onAddExercise,
        onDeleteSession: widget.onDeleteSession,
        onAddSession: widget.onAddSession,
        
        cookbookMeals: widget.cookbookMeals,
        weeklyGoals: widget.weeklyGoals,
        onUpdateWeeklyGoals: widget.onUpdateWeeklyGoals,
        weeklyPlanExtras: widget.weeklyPlanExtras,
        onUpdateWeeklyPlanExtras: widget.onUpdateWeeklyPlanExtras,
      ),
      ExercisesScreen(
        exercises: widget.exercises,
        sessions: widget.sessions,
        onAddExercise: widget.onAddExercise,
        onUpdateExercise: widget.onUpdateExercise,
      ),
      StatsScreen(
        sessions: widget.sessions,
        meals: widget.meals,
        nutritionGoal: widget.nutritionGoal,
        onClearAll: widget.onClearAll,
      ),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onInnerNavTap,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Exercises',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
