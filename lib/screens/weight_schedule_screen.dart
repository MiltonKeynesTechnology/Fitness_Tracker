import 'package:flutter/material.dart';

class WeightScheduleScreen extends StatefulWidget {
  /// Weekdays as DateTime.weekday (Mon=1 … Sun=7)
  final Set<int> initialDays;

  const WeightScheduleScreen({
    super.key,
    required this.initialDays,
  });

  @override
  State<WeightScheduleScreen> createState() => _WeightScheduleScreenState();
}

class _WeightScheduleScreenState extends State<WeightScheduleScreen> {
  late Set<int> _selectedDays;

  @override
  void initState() {
    super.initState();
    _selectedDays = {...widget.initialDays};
  }

  String _dayLabel(int weekday) {
    const labels = {
      DateTime.monday: 'Monday',
      DateTime.tuesday: 'Tuesday',
      DateTime.wednesday: 'Wednesday',
      DateTime.thursday: 'Thursday',
      DateTime.friday: 'Friday',
      DateTime.saturday: 'Saturday',
      DateTime.sunday: 'Sunday',
    };
    return labels[weekday] ?? 'Day $weekday';
  }

  void _toggleDay(int weekday) {
    setState(() {
      if (_selectedDays.contains(weekday)) {
        _selectedDays.remove(weekday);
      } else {
        _selectedDays.add(weekday);
      }
    });
  }

  void _setPresetEveryDay() {
    setState(() {
      _selectedDays = {
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
        DateTime.sunday,
      };
    });
  }

  void _setPresetThreeDays() {
    setState(() {
      _selectedDays = {
        DateTime.monday,
        DateTime.wednesday,
        DateTime.friday,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight logging schedule'),
        actions: [
          TextButton(
            onPressed: () {
              // return the selected set
              Navigator.of(context).pop<Set<int>>(_selectedDays);
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Choose which days you want to record your weight. '
            'You can still log on other days if you like.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Presets
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: _setPresetEveryDay,
                child: const Text('Every day'),
              ),
              OutlinedButton(
                onPressed: _setPresetThreeDays,
                child: const Text('Mon / Wed / Fri'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                for (final weekday in [
                  DateTime.monday,
                  DateTime.tuesday,
                  DateTime.wednesday,
                  DateTime.thursday,
                  DateTime.friday,
                  DateTime.saturday,
                  DateTime.sunday,
                ]) ...[
                  SwitchListTile(
                    title: Text(_dayLabel(weekday)),
                    value: _selectedDays.contains(weekday),
                    onChanged: (_) => _toggleDay(weekday),
                  ),
                  if (weekday != DateTime.sunday)
                    const Divider(height: 0),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
