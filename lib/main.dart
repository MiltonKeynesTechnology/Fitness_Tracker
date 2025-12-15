// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models.dart';
import 'data.dart';
import 'screens/dashboard_screen.dart';
import 'screens/fitness_shell_screen.dart';
import 'screens/nutrition_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';

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
  late List<DailyEnergyEntry> _dailyEnergyEntries;
  String _userName = 'Friend';
  double? _userHeightCm;
  String? _userAvatarPath;

  Set<int> _weighInWeekdays = {
  DateTime.monday,
  DateTime.wednesday,
  DateTime.friday,
  };

  late List<CookbookMeal> _cookbookMeals;

  @override
  void initState() {
    super.initState();
    _loadFromHive();
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  int? _burnedForDate(DateTime date) {
  final d = _dateOnly(date);
  final entry = _dailyEnergyEntries
      .cast<DailyEnergyEntry?>()
      .firstWhere(
        (e) => e != null && _dateOnly(e.date) == d,
        orElse: () => null,
      );
  return entry?.burnedKcal;
  }

  void _onAddCookbookMeal(CookbookMeal template) {
    setState(() {
      final idx = _cookbookMeals.indexWhere((t) => t.id == template.id);
      if (idx == -1) {
        _cookbookMeals.add(template);
      } else {
        _cookbookMeals[idx] = template;
      }
    });
    _saveToHive();
  }

  void _onUpdateBurnedForToday(int burnedKcal) {
  final d = _dateOnly(DateTime.now());
  setState(() {
    final idx = _dailyEnergyEntries.indexWhere(
      (e) => _dateOnly(e.date) == d,
    );
    if (idx == -1) {
      _dailyEnergyEntries.add(
        DailyEnergyEntry(date: d, burnedKcal: burnedKcal),
      );
    } else {
      _dailyEnergyEntries[idx] = DailyEnergyEntry(
        date: d,
        burnedKcal: burnedKcal,
      );
    }
    _dailyEnergyEntries.sort((a, b) => a.date.compareTo(b.date));
  });
  _saveToHive();
  }

  void _loadFromHive() {
    try {
      final exList = widget.box.get('exercises') as List?;
      final sesList = widget.box.get('sessions') as List?;
      final weightList = widget.box.get('weightEntries') as List?;
      final mealsList = widget.box.get('meals') as List?;
      final suppList = widget.box.get('supplements') as List?;
      final goalMap = widget.box.get('nutritionGoal') as Map?;
      final energyList = widget.box.get('dailyEnergy') as List?;
      final weighDaysList = widget.box.get('weighInWeekdays') as List?;
      final storedName = widget.box.get('userName') as String?;
      final storedHeight = widget.box.get('userHeightCm');
      final avatarPath = widget.box.get('userAvatarPath') as String?;
      final cookbookList = widget.box.get('cookbookMeals') as List?;

      _dailyEnergyEntries = energyList == null
          ? []
          : energyList
              .map((m) => DailyEnergyEntry.fromMap(m as Map))
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

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

      _cookbookMeals = cookbookList == null
          ? []
          : cookbookList
              .map((m) => CookbookMeal.fromMap(m as Map))
              .toList();

      // 🔹 restore weigh-in schedule
      _weighInWeekdays = weighDaysList == null
          ? {DateTime.monday, DateTime.wednesday, DateTime.friday}
          : weighDaysList.cast<int>().toSet();

      // 🔹 restore profile
      _userName = storedName ?? 'Friend';
      if (storedHeight is num) {
        _userHeightCm = storedHeight.toDouble();
      } else {
        _userHeightCm = null;
      }
      _userAvatarPath = avatarPath;


      _weighInWeekdays = weighDaysList == null
          ? {DateTime.monday, DateTime.wednesday, DateTime.friday}
          : weighDaysList.cast<int>().toSet();
    } catch (e) {
      // If anything goes wrong, reset to a clean state so the app can still launch.
      _exercises = List.of(defaultExercises);
      _sessions = [];
      _weightEntries = [];
      _meals = [];
      _supplements = [];
      _nutritionGoal = null;
      _dailyEnergyEntries = [];
      _weighInWeekdays = {
        DateTime.monday,
        DateTime.wednesday,
        DateTime.friday,
      };
      _cookbookMeals = [];
      _userName = 'Friend';
      _userHeightCm = null;
      _userAvatarPath = null;
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
    await widget.box.put(
      'dailyEnergy',
      _dailyEnergyEntries.map((e) => e.toMap()).toList(),
    );

    await widget.box.put(
      'weighInWeekdays',
      _weighInWeekdays.toList(),
    );

    await widget.box.put('userName', _userName);
    await widget.box.put('userHeightCm', _userHeightCm);
    await widget.box.put('userAvatarPath', _userAvatarPath);

    await widget.box.put(
      'cookbookMeals',
      _cookbookMeals.map((t) => t.toMap()).toList(),
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
      _dailyEnergyEntries.clear();
      _weighInWeekdays = {
        DateTime.monday,
        DateTime.wednesday,
        DateTime.friday,
      };
      _userName = 'Friend';
      _userHeightCm = null;
      _userAvatarPath = null;
    });
    await widget.box.clear();
  }

  Future<void> _clearWeightData() async {
    setState(() {
      _weightEntries.clear();
    });
    await widget.box.put('weightEntries', []);
  }

  void _onUpdateProfile(String name, double? heightCm) {
    setState(() {
      _userName = name.trim().isEmpty ? 'Friend' : name.trim();
      _userHeightCm = heightCm;
    });
    _saveToHive();
  }

  void _onUpdateWeighInWeekdays(Set<int> days) {
    setState(() {
      _weighInWeekdays = days;
    });
    _saveToHive();
  }

  void _onUpdateAvatarPath(String? path) {
    setState(() {
      _userAvatarPath = path;
    });
    _saveToHive();
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
        // Normalise to "day only" for the new entry
        final d = entry.date;
        final dayKey = DateTime(d.year, d.month, d.day);

        // Look for an existing entry on the same calendar day
        final existingIndex = _weightEntries.indexWhere((w) =>
            w.date.year == dayKey.year &&
            w.date.month == dayKey.month &&
            w.date.day == dayKey.day);

        if (existingIndex != -1) {
          // Replace the existing entry for that day (keep its id)
          final old = _weightEntries[existingIndex];
          _weightEntries[existingIndex] = WeightEntry(
            id: old.id,
            date: entry.date,
            weightKg: entry.weightKg,
          );
        } else {
          // No entry for this day yet → add a new one
          _weightEntries.add(entry);
        }

        // Always keep them sorted
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
  
  void _onUpdateWeighSchedule(Set<int> days) {
  setState(() {
    _weighInWeekdays = days;
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
            _selectedIndex = 1;
          });
        },
        onOpenNutrition: () {
          setState(() {
            _selectedIndex = 2;
          });
        },
        weighInWeekdays: _weighInWeekdays,
        userName: _userName,
        userHeightCm: _userHeightCm,
        avatarPath: _userAvatarPath,
        onOpenProfile: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfileScreen(
                userName: _userName,
                userHeightCm: _userHeightCm,
                weightEntries: _weightEntries,
                weighInWeekdays: _weighInWeekdays,
                onUpdateProfile: _onUpdateProfile,
                onUpdateWeighInWeekdays: _onUpdateWeighInWeekdays,
                avatarPath: _userAvatarPath,
                onUpdateAvatarPath: _onUpdateAvatarPath,
              ),
            ),
          );
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
        weightEntries: _weightEntries,
        onAddMeal: _onAddMealEntry,
        onUpdateMeal: _onUpdateMealEntry,
        onDeleteMeal: _onDeleteMealEntry,
        onAddSupplement: _onAddSupplementEntry,
        onUpdateSupplement: _onUpdateSupplementEntry,
        onDeleteSupplement: _onDeleteSupplementEntry,
        nutritionGoal: _nutritionGoal,
        onUpdateGoal: _onUpdateNutritionGoal,
        burnedToday: _burnedForDate(DateTime.now()),
        onUpdateBurnedToday: _onUpdateBurnedForToday,
        cookbookMeals: _cookbookMeals,            // 🔹 NEW
        onAddCookbookMeal: _onAddCookbookMeal,
      ),

      // 3: Settings
      SettingsScreen(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        onClearAll: _clearAllData,
        onClearWeightLog: _clearWeightData,
        weighInWeekdays: _weighInWeekdays,           // 🔹 NEW
        onUpdateWeighSchedule: _onUpdateWeighSchedule, // 🔹 NEW
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
