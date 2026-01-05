import 'package:flutter/material.dart';

import '../models.dart';
import 'weight_schedule_screen.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final void Function(ThemeMode) onThemeModeChanged;
  final Future<void> Function() onClearAll;
  final VoidCallback onClearWeightLog;

  final Set<int> weighInWeekdays;
  final void Function(Set<int>) onUpdateWeighSchedule;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onClearAll,
    required this.onClearWeightLog,
    required this.weighInWeekdays,
    required this.onUpdateWeighSchedule,
  });

  Future<void> _confirmClearAll(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This will delete all workouts, stats and custom exercises.\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (result != true) return;

    await onClearAll();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data cleared.')),
    );
  }

    String _formatWeighDays() {
    if (weighInWeekdays.length == 7) return 'Every day';
    if (weighInWeekdays.isEmpty) return 'No specific days';

    const shortNames = {
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    };

    final ordered = [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday,
    ].where((d) => weighInWeekdays.contains(d));

    return ordered.map((d) => shortNames[d]!).join(', ');
  }


    Future<void> _confirmClearWeightLog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear bodyweight log?'),
        content: const Text(
          'This will delete all saved weight entries.\n'
          'Your workouts, meals and other data will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (result != true) return;

    onClearWeightLog();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bodyweight log cleared.')),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- THEME ----
          Text(
            'Theme',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('System default'),
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  onChanged: (value) {
                    if (value == null) return;
                    onThemeModeChanged(value);
                  },
                ),
                const Divider(height: 0),
                RadioListTile<ThemeMode>(
                  title: const Text('Light'),
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  onChanged: (value) {
                    if (value == null) return;
                    onThemeModeChanged(value);
                  },
                ),
                const Divider(height: 0),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark'),
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  onChanged: (value) {
                    if (value == null) return;
                    onThemeModeChanged(value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ---- DATA / RESET ----
          Text(
            'Data',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                // NEW: weight schedule config
                ListTile(
                  leading: const Icon(Icons.monitor_weight_outlined),
                  title: const Text('Weight logging schedule'),
                  subtitle: Text(_formatWeighDays()),
                  onTap: () async {
                    final result = await Navigator.of(context).push<Set<int>>(
                      MaterialPageRoute(
                        builder: (_) => WeightScheduleScreen(
                          initialDays: weighInWeekdays,
                        ),
                      ),
                    );
                    if (result != null) {
                      onUpdateWeighSchedule(result);
                    }
                  },
                ),
                const Divider(height: 0),

                // existing clear-weight tile
                ListTile(
                  leading: const Icon(Icons.monitor_weight),
                  title: const Text('Clear bodyweight log'),
                  subtitle: const Text('Delete all saved weight entries'),
                  onTap: () => _confirmClearWeightLog(context),
                ),
                const Divider(height: 0),

                // existing clear-all tile
                ListTile(
                  leading: const Icon(Icons.delete_forever),
                  title: const Text('Clear all training data'),
                  subtitle: const Text('Remove all workouts and exercises'),
                  onTap: () => _confirmClearAll(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
