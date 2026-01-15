import 'package:flutter/material.dart';

import '../models.dart';
import 'planner_screen.dart';

class CalendarScreen extends StatefulWidget {
  final List<WorkoutSession> sessions;
  final List<Exercise> exercises;
  final void Function(WorkoutSession) onAddSession;
  final void Function(WorkoutSession) onDeleteSession;
  final List<CookbookMeal> cookbookMeals;
  final WeeklyNutritionGoals weeklyGoals;
  final void Function(WeeklyNutritionGoals) onUpdateWeeklyGoals;
  final WeeklyPlanExtras weeklyPlanExtras;
  final void Function(WeeklyPlanExtras) onUpdateWeeklyPlanExtras;

  const CalendarScreen({
    super.key,
    required this.sessions,
    required this.exercises,
    required this.onAddSession,
    required this.onDeleteSession,
    required this.cookbookMeals,
    required this.weeklyGoals,
    required this.onUpdateWeeklyGoals,
    required this.weeklyPlanExtras,
    required this.onUpdateWeeklyPlanExtras,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  List<WorkoutSession> _sessionsForDay(DateTime day) {
    final d = _dateOnly(day);
    final list = widget.sessions.where((s) => _dateOnly(s.date) == d).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  int _plannedCountForDay(DateTime day) {
    final d = _dateOnly(day);
    return widget.sessions.where((s) => s.status == WorkoutStatus.planned && _dateOnly(s.date) == d).length;
  }

  int _completedCountForDay(DateTime day) {
    final d = _dateOnly(day);
    return widget.sessions.where((s) => s.status == WorkoutStatus.completed && _dateOnly(s.date) == d).length;
  }

  String _monthLabel(DateTime d) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  Future<void> _openPlanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlannerScreen(
          existingSessions: widget.sessions,
          allExercises: widget.exercises,
          onAddSession: widget.onAddSession,
          onDeleteSession: widget.onDeleteSession,

          cookbookMeals: widget.cookbookMeals,
          weeklyGoals: widget.weeklyGoals,
          onUpdateWeeklyGoals: widget.onUpdateWeeklyGoals,
          weeklyPlanExtras: widget.weeklyPlanExtras,
          onUpdateWeeklyPlanExtras: widget.onUpdateWeeklyPlanExtras,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  void _showDayDetails(DateTime day) {
    final sessions = _sessionsForDay(day);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (sessions.isEmpty)
                Text(
                  'Nothing logged or scheduled for this day yet.',
                  style: theme.textTheme.bodyMedium,
                )
              else
                ...sessions.map((s) {
                  final icon = s.status == WorkoutStatus.completed
                      ? Icons.check_circle
                      : Icons.event_available;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(icon),
                    title: Text(s.name),
                    subtitle: Text(s.status == WorkoutStatus.completed ? 'Completed' : 'Scheduled'),
                  );
                }),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _openPlanner();
                      },
                      icon: const Icon(Icons.edit_calendar),
                      label: const Text('Open planner'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstOfMonth = DateTime(year, month, 1);

    // Monday-first grid (Mon=0 ... Sun=6)
    final firstWeekday = (firstOfMonth.weekday + 6) % 7;
    final totalCells = ((firstWeekday + daysInMonth) <= 35) ? 35 : 42;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            tooltip: 'Open planner',
            icon: const Icon(Icons.edit_calendar),
            onPressed: _openPlanner,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Month header
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    _monthLabel(_focusedMonth),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Weekday labels
            Row(
              children: const [
                _WeekdayLabel('Mon'),
                _WeekdayLabel('Tue'),
                _WeekdayLabel('Wed'),
                _WeekdayLabel('Thu'),
                _WeekdayLabel('Fri'),
                _WeekdayLabel('Sat'),
                _WeekdayLabel('Sun'),
              ],
            ),
            const SizedBox(height: 8),

            // Calendar grid
            Expanded(
              child: GridView.builder(
                itemCount: totalCells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final dayNum = index - firstWeekday + 1;
                  final inMonth = dayNum >= 1 && dayNum <= daysInMonth;

                  if (!inMonth) {
                    return const SizedBox.shrink();
                  }

                  final day = DateTime(year, month, dayNum);
                  final planned = _plannedCountForDay(day);
                  final completed = _completedCountForDay(day);

                  final isSelected = _selectedDay != null && _dateOnly(_selectedDay!) == _dateOnly(day);
                  final isToday = _dateOnly(DateTime.now()) == _dateOnly(day);

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _selectedDay = day);
                      _showDayDetails(day);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                        color: isToday ? theme.colorScheme.primaryContainer.withOpacity(0.35) : null,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$dayNum',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              if (planned > 0)
                                _DotBadge(
                                  color: theme.colorScheme.secondary,
                                  text: planned.toString(),
                                ),
                              if (completed > 0) ...[
                                if (planned > 0) const SizedBox(width: 6),
                                _DotBadge(
                                  color: theme.colorScheme.primary,
                                  text: completed.toString(),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Legend
            const SizedBox(height: 8),
            Row(
              children: [
                _LegendDot(label: 'Scheduled', iconColor: null),
                const SizedBox(width: 16),
                _LegendDot(label: 'Completed', iconColor: null, isCompleted: true),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;
  const _WeekdayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DotBadge extends StatelessWidget {
  final Color color;
  final String text;

  const _DotBadge({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color? iconColor;
  final bool isCompleted;

  const _LegendDot({
    required this.label,
    this.iconColor,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCompleted ? theme.colorScheme.primary : theme.colorScheme.secondary;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
