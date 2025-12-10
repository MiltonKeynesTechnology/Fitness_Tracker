import 'package:flutter/material.dart';

import '../models.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final void Function(ThemeMode) onThemeModeChanged;
  final Future<void> Function() onClearAll;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onClearAll,
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
            child: ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Clear all training data'),
              subtitle: const Text('Remove all workouts and exercises'),
              onTap: () => _confirmClearAll(context),
            ),
          ),

          const SizedBox(height: 24),

          // (Optional) App info
          Text(
            'About',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.fitness_center_outlined),
              title: const Text('Training Tracker'),
              subtitle: const Text('Personal training log & stats'),
            ),
          ),
        ],
      ),
    );
  }
}
