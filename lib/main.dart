// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models.dart';
import 'data.dart';
import 'screens/dashboard_screen.dart';
import 'screens/fitness_shell_screen.dart';
import 'screens/nutrition_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Hive and open a box for our training data
  await Hive.initFlutter();
  final box = await Hive.openBox('training_v2');

  runApp(TrainingTrackerApp(box: box));
}

// TOP-LEVEL APP W/ THEME CONTROL
class TrainingTrackerApp extends StatefulWidget {
  final Box box;

  const TrainingTrackerApp({super.key, required this.box});

  @override
  State<TrainingTrackerApp> createState() => _TrainingTrackerAppState();
}

class _TrainingTrackerAppState extends State<TrainingTrackerApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Training Tracker',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: HomeScreen(
        box: widget.box,
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}

// HOME + OUTER BOTTOM NAV
class HomeScreen extends StatefulWidget {
  final Box box;
  final ThemeMode themeMode;
  final void Function(ThemeMode) onThemeModeChanged;

  const HomeScreen({
    super.key,
    required this.box,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late List<Exercise> _exercises;
  late List<WorkoutSession> _sessions;
  late List<WeightEntry> _weightEntries;
  late List<MealEntry> _meals;
  late List<SupplementEntry> _supplements;
  NutritionGoal? _nutritionGoal;

  @override
  void initState() {
    super.initState();
    _loadFromHive();
  }

  void _loadFromHive() {
    try {
      final exList = widget.box.get('exercises') as List?;
      final sesList = widget.box.get('sessions') as List?;
      final weightList = widget.box.get('weightEntries') as List?;
      final mealsList = widget.box.get('meals') as List?;
      final suppList = widget.box.get('supplements') as List?;
      final goalMap = widget.box.get('nutritionGoal') as Map?;

      // If no exercises saved yet, start with defaultExercises
      _exercises = exList == null || exList.isEmpty
          ? List.of(defaultExercises)
          : exList.map((m) => Exercise.fromMap(m as Map)).toList();

      _sessions = sesList == null
          ? []
          : sesList.map((m) => WorkoutSession.fromMap(m as Map)).toList();

      _weightEntries = weightList == null
          ? []
          : weightList
              .map((m) => WeightEntry.fromMap(m as Map))
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

      _meals = mealsList == null
          ? []
          : mealsList
              .map((m) => MealEntry.fromMap(m as Map))
              .toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      _supplements = suppList == null
          ? []
          : suppList
              .map((m) => SupplementEntry.fromMap(m as Map))
              .toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      _nutritionGoal =
          goalMap == null ? null : NutritionGoal.fromMap(goalMap);
    } catch (e) {
      // If anything goes wrong, reset to a clean state so the app can still launch.
      _exercises = List.of(defaultExercises);
      _sessions = [];
      _weightEntries = [];
      _meals = [];
      _supplements = [];
      _nutritionGoal = null;
      widget.box.clear(); // clear corrupted / incompatible data
    }
  }

  Future<void> _saveToHive() async {
    await widget.box.put(
      'exercises',
      _exercises.map((e) => e.toMap()).toList(),
    );
    await widget.box.put(
      'sessions',
      _sessions.map((s) => s.toMap()).toList(),
    );
    await widget.box.put(
      'weightEntries',
      _weightEntries.map((w) => w.toMap()).toList(),
    );
    await widget.box.put(
      'meals',
      _meals.map((m) => m.toMap()).toList(),
    );
    await widget.box.put(
      'supplements',
      _supplements.map((s) => s.toMap()).toList(),
    );
    await widget.box.put(
      'nutritionGoal',
      _nutritionGoal?.toMap(),
    );
  }

  void _onAddSession(WorkoutSession session) {
    setState(() {
      _sessions.add(session);
    });
    _saveToHive();
  }

  void _onAddExercise(Exercise exercise) {
    setState(() {
      _exercises.add(exercise);
    });
    _saveToHive();
  }

  void _onSessionsChanged() {
    setState(() {});
    _saveToHive();
  }

  void _onDeleteSession(WorkoutSession session) {
    setState(() {
      _sessions.removeWhere((s) => s.id == session.id);
    });
    _saveToHive();
  }

  Future<void> _clearAllData() async {
    setState(() {
      _sessions.clear();
      _exercises = List.of(defaultExercises);
      _weightEntries.clear();
      _meals.clear();
      _supplements.clear();
      _nutritionGoal = null;
    });
    await widget.box.clear(); // wipe all stored data
  }

  void _onUpdateExercise(Exercise updated) {
    setState(() {
      // update master exercise list
      final index = _exercises.indexWhere((e) => e.id == updated.id);
      if (index != -1) {
        _exercises[index] = updated;
      }

      // also update embedded copies inside past sessions
      for (final session in _sessions) {
        for (var i = 0; i < session.exercises.length; i++) {
          final we = session.exercises[i];
          if (we.exercise.id == updated.id) {
            session.exercises[i] = WorkoutExercise(
              id: we.id,
              exercise: updated,
              sets: we.sets,
            );
          }
        }
      }
    });
    _saveToHive();
  }

  void _onAddWeightEntry(WeightEntry entry) {
    setState(() {
      _weightEntries.add(entry);
      _weightEntries.sort((a, b) => a.date.compareTo(b.date));
    });
    _saveToHive();
  }

  void _onAddMealEntry(MealEntry entry) {
    setState(() {
      _meals.add(entry);
      _meals.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    });
    _saveToHive();
  }

  void _onAddSupplementEntry(SupplementEntry entry) {
    setState(() {
      _supplements.add(entry);
      _supplements.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    });
    _saveToHive();
  }

    void _onUpdateMealEntry(MealEntry updated) {
    setState(() {
      final index = _meals.indexWhere((m) => m.id == updated.id);
      if (index != -1) {
        _meals[index] = updated;
        _meals.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      }
    });
    _saveToHive();
  }

  void _onDeleteMealEntry(MealEntry entry) {
    setState(() {
      _meals.removeWhere((m) => m.id == entry.id);
    });
    _saveToHive();
  }

  void _onUpdateSupplementEntry(SupplementEntry updated) {
    setState(() {
      final index = _supplements.indexWhere((s) => s.id == updated.id);
      if (index != -1) {
        _supplements[index] = updated;
        _supplements.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      }
    });
    _saveToHive();
  }

  void _onDeleteSupplementEntry(SupplementEntry entry) {
    setState(() {
      _supplements.removeWhere((s) => s.id == entry.id);
    });
    _saveToHive();
  }

  void _onUpdateNutritionGoal(NutritionGoal? goal) {
    setState(() {
      _nutritionGoal = goal;
    });
    _saveToHive();
  }

  void _onOuterNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  //   void _onDeleteMealEntry(MealEntry entry) {
  //   setState(() {
  //     _meals.removeWhere((m) => m.id == entry.id);
  //   });
  //   _saveToHive();
  // }

  // void _onDeleteSupplementEntry(SupplementEntry entry) {
  //   setState(() {
  //     _supplements.removeWhere((s) => s.id == entry.id);
  //   });
  //   _saveToHive();
  // }

  @override
  Widget build(BuildContext context) {
    final pages = [
      // 0: Dashboard
      DashboardScreen(
        sessions: _sessions,
        weightEntries: _weightEntries,
        meals: _meals,
        onAddWeight: _onAddWeightEntry,
        onOpenFitness: () {
          setState(() {
            _selectedIndex = 1; // jump to Fitness tab
          });
        },
        onOpenNutrition: () {
          setState(() {
            _selectedIndex = 2; // jump to Nutrition tab
          });
        },
      ),

      // 1: Fitness module (with its own inner bottom nav)
      FitnessShellScreen(
        exercises: _exercises,
        sessions: _sessions,
        onAddSession: _onAddSession,
        onAddExercise: _onAddExercise,
        onSessionsChanged: _onSessionsChanged,
        onDeleteSession: _onDeleteSession,
        onUpdateExercise: _onUpdateExercise,
        onClearAll: _clearAllData,
        meals: _meals,
        nutritionGoal: _nutritionGoal,
      ),

      // 2: Nutrition module
      NutritionScreen(
        meals: _meals,
        supplements: _supplements,
        onAddMeal: _onAddMealEntry,
        onUpdateMeal: _onUpdateMealEntry,
        onDeleteMeal: _onDeleteMealEntry,
        onAddSupplement: _onAddSupplementEntry,
        onUpdateSupplement: _onUpdateSupplementEntry,
        onDeleteSupplement: _onDeleteSupplementEntry,
        nutritionGoal: _nutritionGoal,
        onUpdateGoal: _onUpdateNutritionGoal,
      ),

      // 3: Settings
      SettingsScreen(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        onClearAll: _clearAllData,
      ),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onOuterNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Fitness',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Nutrition',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
