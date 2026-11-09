import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/core/utils/recurrence_engine.dart';
import 'package:noteon/data/models/note_model.dart';
import 'package:noteon/data/models/task_list_model.dart';
import 'package:noteon/data/models/task_model.dart';
import 'package:noteon/data/providers/repository_providers.dart';
import 'package:noteon/features/reminders/reminder_service.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String? taskId;
  final String? initialListId;
  final String? initialNoteId;

  const TaskDetailScreen({
    super.key,
    this.taskId,
    this.initialListId,
    this.initialNoteId,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subtaskInputController = TextEditingController();

  TaskModel? _existingTask;
  bool _isLoading = true;

  String _status = 'todo';
  String _priority = 'none';
  DateTime? _dueDate;
  bool _hasTime = false;
  RepeatRule? _repeatRule;
  String? _listId;
  String? _noteId;
  List<String> _labelIds = [];
  int _timeSpentSec = 0;

  // Subtasks list
  final List<TaskModel> _subtasks = [];

  // Focus Timer (Pomodoro) state
  Timer? _pomodoroTimer;
  int _pomodoroSecondsRemaining = 25 * 60; // 25 min
  bool _isPomodoroRunning = false;

  @override
  void initState() {
    super.initState();
    _listId = widget.initialListId;
    _noteId = widget.initialNoteId;
    _loadTask();
  }

  @override
  void dispose() {
    _pomodoroTimer?.cancel();
    _titleController.dispose();
    _descController.dispose();
    _subtaskInputController.dispose();
    super.dispose();
  }

  Future<void> _loadTask() async {
    if (widget.taskId != null &&
        widget.taskId!.isNotEmpty &&
        widget.taskId != 'new') {
      final repo = ref.read(tasksRepositoryProvider);
      final task = await repo.getTaskById(widget.taskId!);
      if (task != null) {
        _existingTask = task;
        _titleController.text = task.title;
        _descController.text = task.description;
        _status = task.status;
        _priority = task.priority;
        _dueDate = task.dueAt;
        _hasTime = task.hasTime;
        _repeatRule = task.repeatRule;
        _listId = task.listId;
        _noteId = task.noteId;
        _labelIds = List.from(task.labelIds);
        _timeSpentSec = task.timeSpentSec;
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final user =
        ref.read(authStateProvider).valueOrNull ??
        ref.read(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? 'guest_user';

    final repo = ref.read(tasksRepositoryProvider);

    if (_existingTask == null) {
      final newTask = TaskModel(
        id: '',
        ownerId: uid,
        memberIds: [uid],
        roles: {uid: 'owner'},
        title: title,
        description: _descController.text.trim(),
        status: _status,
        priority: _priority,
        dueAt: _dueDate,
        hasTime: _hasTime,
        repeatRule: _repeatRule,
        listId: _listId,
        noteId: _noteId,
        labelIds: _labelIds,
        timeSpentSec: _timeSpentSec,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final res = await repo.createTask(newTask);
      if (res.isSuccess && _dueDate != null) {
        // Schedule local reminder notification
        await ReminderService.instance.scheduleTaskReminder(
          taskId: res.dataOrNull?.id ?? '',
          title: title,
          remindAt: _dueDate!,
          body: _descController.text.trim(),
        );
      }
    } else {
      final updated = _existingTask!.copyWith(
        title: title,
        description: _descController.text.trim(),
        status: _status,
        priority: _priority,
        dueAt: _dueDate,
        clearDueAt: _dueDate == null,
        hasTime: _hasTime,
        repeatRule: _repeatRule,
        clearRepeatRule: _repeatRule == null,
        listId: _listId,
        clearListId: _listId == null,
        noteId: _noteId,
        clearNoteId: _noteId == null,
        labelIds: _labelIds,
        timeSpentSec: _timeSpentSec,
        updatedAt: DateTime.now(),
      );
      await repo.updateTask(updated);

      if (_dueDate != null) {
        await ReminderService.instance.scheduleTaskReminder(
          taskId: _existingTask!.id,
          title: title,
          remindAt: _dueDate!,
          body: _descController.text.trim(),
        );
      }
    }

    if (mounted) context.pop();
  }

  void _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      TimeOfDay? time;
      if (mounted) {
        final withTime = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Add Time?'),
            content: const Text(
              'Do you want to set a specific time for this task?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Date only'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Set time'),
              ),
            ],
          ),
        );

        if (withTime == true && mounted) {
          time = await showTimePicker(
            context: context,
            initialTime: _dueDate != null
                ? TimeOfDay.fromDateTime(_dueDate!)
                : const TimeOfDay(hour: 9, minute: 0),
          );
        }
      }

      setState(() {
        if (time != null) {
          _dueDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
          _hasTime = true;
        } else {
          _dueDate = DateTime(picked.year, picked.month, picked.day, 23, 59);
          _hasTime = false;
        }
      });
    }
  }

  void _showRecurrenceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Does not repeat'),
              trailing: _repeatRule == null ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() => _repeatRule = null);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Daily'),
              trailing: _repeatRule?.frequency == 'daily'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                setState(
                  () => _repeatRule = const RepeatRule(frequency: 'daily'),
                );
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Weekly'),
              trailing: _repeatRule?.frequency == 'weekly'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                setState(
                  () => _repeatRule = const RepeatRule(frequency: 'weekly'),
                );
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Monthly'),
              trailing: _repeatRule?.frequency == 'monthly'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                setState(
                  () => _repeatRule = const RepeatRule(frequency: 'monthly'),
                );
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('After completion (3 days)'),
              trailing: _repeatRule?.frequency == 'after_completion'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                setState(
                  () => _repeatRule = const RepeatRule(
                    frequency: 'after_completion',
                    afterCompletionDays: 3,
                  ),
                );
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _togglePomodoro() {
    if (_isPomodoroRunning) {
      _pomodoroTimer?.cancel();
      setState(() => _isPomodoroRunning = false);
    } else {
      setState(() => _isPomodoroRunning = true);
      _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_pomodoroSecondsRemaining > 0) {
          setState(() {
            _pomodoroSecondsRemaining--;
            _timeSpentSec++;
          });
        } else {
          timer.cancel();
          setState(() => _isPomodoroRunning = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pomodoro completed! Take a 5-minute break. 🍅'),
            ),
          );
        }
      });
    }
  }

  void _resetPomodoro() {
    _pomodoroTimer?.cancel();
    setState(() {
      _isPomodoroRunning = false;
      _pomodoroSecondsRemaining = 25 * 60;
    });
  }

  Future<void> _addSubtask() async {
    final title = _subtaskInputController.text.trim();
    if (title.isEmpty || _existingTask == null) return;

    final user =
        ref.read(authStateProvider).valueOrNull ??
        ref.read(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? 'guest_user';

    final sub = TaskModel(
      id: '',
      ownerId: uid,
      memberIds: [uid],
      roles: {uid: 'owner'},
      title: title,
      parentTaskId: _existingTask!.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final res = await ref.read(tasksRepositoryProvider).createTask(sub);
    if (res.isSuccess && res.dataOrNull != null) {
      _subtaskInputController.clear();
      setState(() {
        _subtasks.add(res.dataOrNull!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final user =
        ref.watch(authStateProvider).valueOrNull ??
        ref.read(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? 'guest_user';

    final listsStream = ref
        .watch(taskListsRepositoryProvider)
        .watchTaskLists(uid: uid);
    final notesStream = ref.watch(notesRepositoryProvider).watchNotes(uid: uid);

    final pomodoroMinutes = (_pomodoroSecondsRemaining ~/ 60)
        .toString()
        .padLeft(2, '0');
    final pomodoroSeconds = (_pomodoroSecondsRemaining % 60).toString().padLeft(
      2,
      '0',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _existingTask == null
              ? (l10n?.newTask ?? 'New Task')
              : 'Task Details',
        ),
        actions: [
          if (_existingTask != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                await ref
                    .read(tasksRepositoryProvider)
                    .deleteTask(_existingTask!.id);
                if (context.mounted) context.pop();
              },
            ),
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _saveTask,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: l10n?.tasksTitle ?? 'Task Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add description / notes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Status Selector Chips
              Text(
                'Status',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: Text(l10n?.statusTodo ?? 'To Do'),
                    selected: _status == 'todo',
                    onSelected: (val) {
                      if (val) setState(() => _status = 'todo');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(l10n?.statusInProgress ?? 'In Progress'),
                    selected: _status == 'in_progress',
                    onSelected: (val) {
                      if (val) setState(() => _status = 'in_progress');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(l10n?.statusDone ?? 'Done'),
                    selected: _status == 'done',
                    onSelected: (val) {
                      if (val) setState(() => _status = 'done');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Priority Selector
              Text(
                'Priority',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final p in ['none', 'low', 'medium', 'high', 'urgent'])
                    ChoiceChip(
                      avatar: p != 'none'
                          ? Icon(
                              Icons.flag_rounded,
                              size: 16,
                              color: p == 'urgent' || p == 'high'
                                  ? Colors.red
                                  : Colors.orange,
                            )
                          : null,
                      label: Text(p.toUpperCase()),
                      selected: _priority == p,
                      onSelected: (val) {
                        if (val) setState(() => _priority = p);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Due Date & Recurrence
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_outlined),
                        title: Text(l10n?.dueDate ?? 'Due Date'),
                        subtitle: Text(
                          _dueDate != null
                              ? (_hasTime
                                    ? DateFormat('EEE, MMM d, yyyy • h:mm a')
                                          .format(_dueDate!)
                                    : DateFormat('EEE, MMM d, yyyy')
                                          .format(_dueDate!))
                              : 'No due date',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_dueDate != null)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () =>
                                    setState(() => _dueDate = null),
                              ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                            ),
                          ],
                        ),
                        onTap: _pickDueDate,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.repeat_rounded),
                        title: Text(l10n?.repeat ?? 'Repeat'),
                        subtitle: Text(
                          _repeatRule?.frequency.toUpperCase() ?? 'None',
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                        ),
                        onTap: _showRecurrenceDialog,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Project List Selector
              StreamBuilder<List<TaskListModel>>(
                stream: listsStream,
                builder: (context, snap) {
                  final lists = snap.data ?? [];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: DropdownButtonFormField<String?>(
                        initialValue: _listId,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.list_alt_rounded),
                          labelText: 'Task List / Project',
                          border: InputBorder.none,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No List (Inbox)'),
                          ),
                          for (final l in lists)
                            DropdownMenuItem(value: l.id, child: Text(l.name)),
                        ],
                        onChanged: (val) => setState(() => _listId = val),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Linked Note Selector
              StreamBuilder<List<NoteModel>>(
                stream: notesStream,
                builder: (context, snap) {
                  final notes = snap.data ?? [];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: DropdownButtonFormField<String?>(
                        initialValue: _noteId,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.note_alt_outlined),
                          labelText: 'Linked Note',
                          border: InputBorder.none,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('None'),
                          ),
                          for (final n in notes)
                            DropdownMenuItem(
                              value: n.id,
                              child: Text(
                                n.title.isNotEmpty ? n.title : 'Untitled Note',
                              ),
                            ),
                        ],
                        onChanged: (val) => setState(() => _noteId = val),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Subtasks Section (if task is saved)
              if (_existingTask != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n?.subtasks ?? 'Subtasks',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_subtasks.where((s) => s.isDone).length}/${_subtasks.length}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                if (_subtasks.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: _subtasks.isEmpty
                        ? 0
                        : _subtasks.where((s) => s.isDone).length /
                              _subtasks.length,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
                const SizedBox(height: 8),
                for (final sub in _subtasks)
                  Row(
                    children: [
                      Checkbox(
                        value: sub.isDone,
                        onChanged: (val) {
                          ref.read(tasksRepositoryProvider).completeTask(sub);
                          setState(() {
                            final idx = _subtasks.indexWhere(
                              (s) => s.id == sub.id,
                            );
                            if (idx != -1) {
                              _subtasks[idx] = sub.copyWith(
                                status: val == true ? 'done' : 'todo',
                              );
                            }
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          sub.title,
                          style: TextStyle(
                            decoration: sub.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subtaskInputController,
                        decoration: InputDecoration(
                          hintText: l10n?.addSubtask ?? 'Add subtask...',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addSubtask(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addSubtask,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Focus Timer (Pomodoro) section
              Card(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.2,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Colors.deepOrange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n?.focusTimer ?? 'Focus Timer (Pomodoro)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Time spent: ${_timeSpentSec ~/ 60}m',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$pomodoroMinutes:$pomodoroSeconds',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: _togglePomodoro,
                            icon: Icon(
                              _isPomodoroRunning
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                            label: Text(
                              _isPomodoroRunning
                                  ? (l10n?.pauseTimer ?? 'Pause')
                                  : (l10n?.startTimer ?? 'Start'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _resetPomodoro,
                            child: Text(l10n?.resetTimer ?? 'Reset'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              FilledButton(
                onPressed: _saveTask,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n?.save ?? 'Save Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
