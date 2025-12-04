// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models.dart';
import 'data.dart';
import 'screens/today_screen.dart';
import 'screens/history_screen.dart';
import 'screens/exercises_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Hive and open a box for our training data
  await Hive.initFlutter();
  final box = await Hive.openBox('training');

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

// HOME + BOTTOM NAV
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

  @override
  void initState() {
    super.initState();
    _loadFromHive();
  }

  void _loadFromHive() {
    final exList = widget.box.get('exercises') as List?;
    final sesList = widget.box.get('sessions') as List?;

    // If no exercises saved yet, start with defaultExercises
    _exercises = exList == null || exList.isEmpty
        ? List.of(defaultExercises)
        : exList
            .map((m) => Exercise.fromMap(m as Map))
            .toList();

    _sessions = sesList == null
        ? []
        : sesList
            .map((m) => WorkoutSession.fromMap(m as Map))
            .toList();
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
    // Called when an existing session is edited (sets changed, name changed, etc.)
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
    });
    await widget.box.clear(); // wipe all stored data
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onUpdateExercise(Exercise updated) {
    setState(() {
      final index = _exercises.indexWhere((e) => e.id == updated.id);
      if (index != -1) {
        _exercises[index] = updated;
      }
    });
    _saveToHive();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayScreen(
        exercises: _exercises,
        onSaveSession: _onAddSession,
        onAddExercise: _onAddExercise,
      ),
      HistoryScreen(
        sessions: _sessions,
        exercises: _exercises,
        onSessionsChanged: _onSessionsChanged,
        onAddExercise: _onAddExercise,
        onDeleteSession: _onDeleteSession,
      ),
      ExercisesScreen(
        exercises: _exercises,
        sessions: _sessions,
        onAddExercise: _onAddExercise,
        onUpdateExercise: _onUpdateExercise,
      ),
      StatsScreen(
        sessions: _sessions,
        onClearAll: _clearAllData,
      ),
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
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurfaceVariant,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
