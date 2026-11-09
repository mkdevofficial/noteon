import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/data/models/note_model.dart';
import 'package:noteon/data/models/task_model.dart';
import 'package:noteon/data/providers/repository_providers.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final user =
        ref.watch(authStateProvider).valueOrNull ??
        ref.read(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? 'guest_user';

    final tasksStream = ref.watch(tasksRepositoryProvider).watchTasks(uid: uid);
    final notesStream = ref.watch(notesRepositoryProvider).watchNotes(uid: uid);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.navCalendar ?? 'Calendar',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<TaskModel>>(
          stream: tasksStream,
          builder: (context, taskSnap) {
            final tasks = taskSnap.data ?? [];

            return StreamBuilder<List<NoteModel>>(
              stream: notesStream,
              builder: (context, noteSnap) {
                final notes = noteSnap.data ?? [];

                // Tasks due on selected day
                final selectedTasks = tasks.where((t) {
                  if (t.dueAt == null) return false;
                  return _isSameDate(t.dueAt!, _selectedDay);
                }).toList();

                // Notes created on selected day
                final selectedNotes = notes.where((n) {
                  return _isSameDate(n.createdAt, _selectedDay);
                }).toList();

                return Column(
                  children: [
                    TableCalendar(
                      firstDay: DateTime(2020),
                      lastDay: DateTime(2030),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() => _calendarFormat = format);
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      eventLoader: (day) {
                        final dayTasks = tasks.where(
                          (t) => t.dueAt != null && _isSameDate(t.dueAt!, day),
                        );
                        final dayNotes = notes.where(
                          (n) => _isSameDate(n.createdAt, day),
                        );
                        return [...dayTasks, ...dayNotes];
                      },
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                      ),
                    ),
                    const Divider(height: 1),

                    // Day Details Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('EEEE, MMMM d').format(_selectedDay),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${selectedTasks.length} tasks • ${selectedNotes.length} notes',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Selected Day Items List
                    Expanded(
                      child: (selectedTasks.isEmpty && selectedNotes.isEmpty)
                          ? Center(
                              child: Text(
                                'No tasks or notes for this date.',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              children: [
                                if (selectedTasks.isNotEmpty) ...[
                                  Text(
                                    l10n?.tasksTitle ?? 'Tasks',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  for (final t in selectedTasks)
                                    Card(
                                      child: ListTile(
                                        leading: Checkbox(
                                          value: t.isDone,
                                          onChanged: (_) {
                                            ref
                                                .read(tasksRepositoryProvider)
                                                .completeTask(t);
                                          },
                                        ),
                                        title: Text(
                                          t.title,
                                          style: TextStyle(
                                            decoration: t.isDone
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        subtitle: t.hasTime
                                            ? Text(
                                                DateFormat('h:mm a')
                                                    .format(t.dueAt!),
                                              )
                                            : null,
                                        onTap: () =>
                                            context.push('/task/${t.id}'),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                ],
                                if (selectedNotes.isNotEmpty) ...[
                                  Text(
                                    l10n?.notesTitle ?? 'Notes',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.secondary,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  for (final n in selectedNotes)
                                    Card(
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.note_alt_outlined,
                                        ),
                                        title: Text(
                                          n.title.isNotEmpty
                                              ? n.title
                                              : 'Untitled Note',
                                        ),
                                        subtitle: Text(
                                          n.plainText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        onTap: () =>
                                            context.push('/note/${n.id}'),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
