// lib/screens/profile_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final double? userHeightCm;
  final List<WeightEntry> weightEntries;

  final Set<int> weighInWeekdays;
  final void Function(String name, double? heightCm) onUpdateProfile;
  final void Function(Set<int> days) onUpdateWeighInWeekdays;

  final String? avatarPath;
  final void Function(String? path) onUpdateAvatarPath;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userHeightCm,
    required this.weightEntries,
    required this.weighInWeekdays,
    required this.onUpdateProfile,
    required this.onUpdateWeighInWeekdays,
    required this.avatarPath,
    required this.onUpdateAvatarPath,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _name;
  double? _heightCm;
  late Set<int> _selectedDays;

  @override
  void initState() {
    super.initState();
    _name = widget.userName;
    _heightCm = widget.userHeightCm;
    _selectedDays = {...widget.weighInWeekdays};
  }

  WeightEntry? get _latestWeight {
    if (widget.weightEntries.isEmpty) return null;
    final sorted = [...widget.weightEntries]
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted.last;
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );

    if (file == null) return;

    widget.onUpdateAvatarPath(file.path);
    setState(() {});
  }

  Future<void> _editProfileInfo(BuildContext context) async {
    final nameCtrl = TextEditingController(text: _name);
    final heightCtrl = TextEditingController(
      text: _heightCm?.toStringAsFixed(0) ?? '',
    );

    double? _parseHeight(String text) {
      final t = text.trim();
      if (t.isEmpty) return null;
      final v = double.tryParse(t.replaceAll(',', '.'));
      if (v == null || v <= 0) return null;
      return v;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Joe',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: heightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                hintText: 'e.g. 180',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final newName = nameCtrl.text.trim();
    final newHeight = _parseHeight(heightCtrl.text);

    setState(() {
      _name = newName.isEmpty ? 'Friend' : newName;
      _heightCm = newHeight;
    });

    widget.onUpdateProfile(_name, _heightCm);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = _latestWeight;

    ImageProvider? avatarImage;
    if (widget.avatarPath != null && widget.avatarPath!.isNotEmpty) {
      avatarImage = FileImage(File(widget.avatarPath!));
    }

    // Simple BMI
    double? bmi;
    if (latest != null && _heightCm != null && _heightCm! > 0) {
      final hM = _heightCm! / 100.0;
      bmi = latest.weightKg / (hM * hM);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- TOP: profile info ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? Text(
                                _name.isEmpty
                                    ? 'U'
                                    : _name.characters.first.toUpperCase(),
                                style: theme.textTheme.titleLarge,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickAvatar,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _name.isEmpty ? 'Friend' : _name,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editProfileInfo(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _heightCm == null
                              ? 'Height: –'
                              : 'Height: ${_heightCm!.toStringAsFixed(0)} cm',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (latest != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Latest weight: ${latest.weightKg.toStringAsFixed(1)} kg '
                            '(${_formatDate(latest.date)})',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                        if (bmi != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'BMI: ${bmi.toStringAsFixed(1)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- WEIGH-IN SCHEDULE ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weigh-in schedule',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose which days you plan to log your weight.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (int weekday = 1; weekday <= 7; weekday++)
                        FilterChip(
                          label: Text(_weekdayLabel(weekday)),
                          selected: _selectedDays.contains(weekday),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedDays.add(weekday);
                              } else {
                                _selectedDays.remove(weekday);
                              }
                            });
                            widget.onUpdateWeighInWeekdays(_selectedDays);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedDays.isEmpty
                        ? 'No scheduled days – you can still log anytime.'
                        : 'You\'ll be nudged to weigh in on: '
                          '${_selectedDays.toList()..sort()}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- BADGES / ACHIEVEMENTS PLACEHOLDER ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Badges & achievements',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Coming soon: earn badges for consistency, streaks, strength PRs, '
                    'nutrition adherence and more.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      Chip(label: Text('7-day weight streak')),
                      Chip(label: Text('Consistent calories')),
                      Chip(label: Text('Workout streak')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
