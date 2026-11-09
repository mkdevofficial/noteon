import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/data/models/task_list_model.dart';
import 'package:noteon/data/models/task_model.dart';
import 'package:noteon/data/providers/repository_providers.dart';
import 'package:noteon/features/home/sync_status_indicator.dart';
import 'package:noteon/features/tasks/kanban_board_view.dart';

enum TaskViewType { list, kanban, agenda }

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _activeSmartList = 'all'; // 'all', 'today', 'upcoming', 'overdue', 'important', 'nodate', 'completed'
  String? _selectedListId;
  TaskViewType _viewType = TaskViewType.list;

  // Multi-select bulk mode
  bool _isBulkMode = false;
  final Set<String> _selectedTaskIds = {};

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedTaskIds.contains(id)) {
        _selectedTaskIds.remove(id);
        if (_selectedTaskIds.isEmpty) _isBulkMode = false;
      } else {
        _selectedTaskIds.add(id);
      }
    });
  }

  void _clearBulkSelection() {
    setState(() {
      _isBulkMode = false;
      _selectedTaskIds.clear();
    });
  }

  Future<void> _bulkComplete(bool done) async {
    final repo = ref.read(tasksRepositoryProvider);
    await repo.bulkComplete(_selectedTaskIds.toList(), done);
    _clearBulkSelection();
  }

  Future<void> _bulkDelete() async {
    final repo = ref.read(tasksRepositoryProvider);
    final count = _selectedTaskIds.length;
    await repo.bulkDelete(_selectedTaskIds.toList());
    _clearBulkSelection();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$count tasks deleted')));
    }
  }

  Future<void> _bulkPostponeDay() async {
    final repo = ref.read(tasksRepositoryProvider);
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 18, 0);
    await repo.bulkSetDueDate(_selectedTaskIds.toList(), tomorrow);
    _clearBulkSelection();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Postponed by 1 day')));
    }
  }

  void _showNewListDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Project / Task List'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'List Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final user =
                    ref.read(authStateProvider).valueOrNull ??
                    ref.read(authRepositoryProvider).currentUser;
                final uid = user?.uid ?? 'guest_user';
                final repo = ref.read(taskListsRepositoryProvider);
                await repo.createTaskList(
                  TaskListModel(
                    id: '',
                    ownerId: uid,
                    memberIds: [uid],
                    roles: {uid: 'owner'},
                    name: name,
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
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
    final listsStream = ref
        .watch(taskListsRepositoryProvider)
        .watchTaskLists(uid: uid);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isBulkMode
              ? '${_selectedTaskIds.length} selected'
              : (l10n?.tasksTitle ?? 'Tasks'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: _isBulkMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearBulkSelection,
              )
            : null,
        actions: [
          if (!_isBulkMode) ...[
            const SyncStatusIndicator(),
            // View Switcher (List vs Kanban vs Agenda)
            IconButton(
              icon: Icon(
                _viewType == TaskViewType.kanban
                    ? Icons.view_kanban_rounded
                    : _viewType == TaskViewType.agenda
                    ? Icons.view_agenda_rounded
                    : Icons.format_list_bulleted_rounded,
              ),
              tooltip: 'Switch View',
              onPressed: () {
                setState(() {
                  _viewType = switch (_viewType) {
                    TaskViewType.list => TaskViewType.kanban,
                    TaskViewType.kanban => TaskViewType.agenda,
                    TaskViewType.agenda => TaskViewType.list,
                  };
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Mark Done',
              onPressed: () => _bulkComplete(true),
            ),
            IconButton(
              icon: const Icon(Icons.update_rounded),
              tooltip: 'Postpone 1 Day',
              onPressed: _bulkPostponeDay,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete Selected',
              onPressed: _bulkDelete,
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<TaskListModel>>(
          stream: listsStream,
          builder: (context, listsSnap) {
            final taskLists = listsSnap.data ?? [];

            return StreamBuilder<List<TaskModel>>(
              stream: tasksStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allTasks = snapshot.data ?? [];
                final now = DateTime.now();
                final todayMidnight = DateTime(now.year, now.month, now.day);
                final tomorrowMidnight = todayMidnight.add(
                  const Duration(days: 1),
                );

                // Smart List Filtering
                List<TaskModel> filteredTasks = allTasks.where((t) {
                  if (t.isSubtask) {
                    return false; // Hide subtasks from top-level lists
                  }
                  if (_selectedListId != null && t.listId != _selectedListId) {
                    return false;
                  }

                  switch (_activeSmartList) {
                    case 'today':
                      if (t.isDone) return false;
                      if (t.dueAt == null) return false;
                      return t.dueAt!.isAfter(todayMidnight) &&
                          t.dueAt!.isBefore(
                            tomorrowMidnight.add(const Duration(days: 1)),
                          );
                    case 'upcoming':
                      if (t.isDone) return false;
                      if (t.dueAt == null) return false;
                      return t.dueAt!.isAfter(tomorrowMidnight);
                    case 'overdue':
                      if (t.isDone) return false;
                      if (t.dueAt == null) return false;
                      return t.dueAt!.isBefore(todayMidnight);
                    case 'important':
                      if (t.isDone) return false;
                      return t.priority == 'high' || t.priority == 'urgent';
                    case 'nodate':
                      if (t.isDone) return false;
                      return t.dueAt == null;
                    case 'completed':
                      return t.isDone;
                    case 'all':
                    default:
                      return true;
                  }
                }).toList();

                return Column(
                  children: [
                    // Smart List Pills Bar
                    _buildSmartListPills(l10n, allTasks),

                    // Project / Task List Selector Bar
                    _buildTaskListSelector(taskLists),

                    // Main Tasks Content (List, Kanban, or Agenda)
                    Expanded(
                      child: _viewType == TaskViewType.kanban
                          ? KanbanBoardView(allTasks: filteredTasks)
                          : _viewType == TaskViewType.agenda
                          ? _buildAgendaView(filteredTasks, theme, l10n)
                          : _buildListView(
                              filteredTasks,
                              allTasks,
                              theme,
                              l10n,
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

  Widget _buildSmartListPills(
    AppLocalizations? l10n,
    List<TaskModel> allTasks,
  ) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final tomorrowMidnight = todayMidnight.add(const Duration(days: 1));

    final countToday = allTasks
        .where(
          (t) =>
              !t.isDone &&
              t.dueAt != null &&
              t.dueAt!.isAfter(todayMidnight) &&
              t.dueAt!.isBefore(tomorrowMidnight.add(const Duration(days: 1))),
        )
        .length;
    final countOverdue = allTasks
        .where(
          (t) =>
              !t.isDone && t.dueAt != null && t.dueAt!.isBefore(todayMidnight),
        )
        .length;
    final countImportant = allTasks
        .where(
          (t) => !t.isDone && (t.priority == 'high' || t.priority == 'urgent'),
        )
        .length;

    final smartLists = [
      {
        'key': 'all',
        'label': l10n?.smartListAll ?? 'All',
        'badge': allTasks.where((t) => !t.isDone).length,
      },
      {
        'key': 'today',
        'label': l10n?.smartListToday ?? 'Today',
        'badge': countToday,
      },
      {
        'key': 'upcoming',
        'label': l10n?.smartListUpcoming ?? 'Upcoming',
        'badge': null,
      },
      {
        'key': 'overdue',
        'label': l10n?.smartListOverdue ?? 'Overdue',
        'badge': countOverdue,
      },
      {
        'key': 'important',
        'label': l10n?.smartListImportant ?? 'Important',
        'badge': countImportant,
      },
      {
        'key': 'nodate',
        'label': l10n?.smartListNoDate ?? 'No Date',
        'badge': null,
      },
      {
        'key': 'completed',
        'label': l10n?.smartListCompleted ?? 'Completed',
        'badge': null,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          for (final item in smartLists) ...[
            ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item['label'] as String),
                  if (item['badge'] != null && (item['badge'] as int) > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: item['key'] == 'overdue'
                            ? Colors.red
                            : Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${item['badge']}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: item['key'] == 'overdue' ? Colors.white : null,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selected: _activeSmartList == item['key'],
              onSelected: (_) {
                setState(() => _activeSmartList = item['key'] as String);
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskListSelector(List<TaskListModel> lists) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    avatar: const Icon(Icons.inbox_rounded, size: 16),
                    label: const Text('All Projects'),
                    selected: _selectedListId == null,
                    onSelected: (_) => setState(() => _selectedListId = null),
                  ),
                  for (final l in lists) ...[
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: CircleAvatar(
                        backgroundColor: Color(l.color),
                        radius: 6,
                      ),
                      label: Text(l.name),
                      selected: _selectedListId == l.id,
                      onSelected: (selected) {
                        setState(
                          () => _selectedListId = selected ? l.id : null,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 20),
            tooltip: 'New Project',
            onPressed: () => _showNewListDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(
    List<TaskModel> tasks,
    List<TaskModel> allTasks,
    ThemeData theme,
    AppLocalizations? l10n,
  ) {
    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n?.emptyTasksTitle ?? 'No tasks here',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n?.emptyTasksSubtitle ??
                    'Enjoy your day or tap + to add a task.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final repo = ref.read(tasksRepositoryProvider);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isSelected = _selectedTaskIds.contains(task.id);
        final subtasks = allTasks
            .where((t) => t.parentTaskId == task.id)
            .toList();

        return Dismissible(
          key: ValueKey(task.id),
          direction: DismissDirection.horizontal,
          background: Container(
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsets.only(left: 20),
            color: Colors.green,
            child: const Icon(Icons.check_rounded, color: Colors.white),
          ),
          secondaryBackground: Container(
            alignment: AlignmentDirectional.centerEnd,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.orange,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.update_rounded, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  '+1 Day',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              // Complete task
              await repo.completeTask(task);
              return false; // let reactive stream update UI
            } else {
              // Postpone +1 day
              final now = DateTime.now();
              final next = (task.dueAt ?? now).add(const Duration(days: 1));
              await repo.updateTask(task.copyWith(dueAt: next));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task postponed by 1 day')),
                );
              }
              return false;
            }
          },
          child: Card(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : null,
            child: InkWell(
              onTap: () {
                if (_isBulkMode) {
                  _toggleSelect(task.id);
                } else {
                  context.push('/task/${task.id}');
                }
              },
              onLongPress: () {
                setState(() => _isBulkMode = true);
                _toggleSelect(task.id);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_isBulkMode)
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelect(task.id),
                          )
                        else
                          Checkbox(
                            value: task.isDone,
                            onChanged: (_) {
                              repo.completeTask(task);
                            },
                          ),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              decoration: task.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (task.priority != 'none')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (task.priority == 'urgent' ||
                                      task.priority == 'high')
                                  ? Colors.red.withValues(alpha: 0.15)
                                  : Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.priority.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color:
                                    (task.priority == 'urgent' ||
                                        task.priority == 'high')
                                    ? Colors.red
                                    : Colors.orange,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (task.description.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 48, bottom: 4),
                        child: Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                    // Subtasks progress if any
                    if (subtasks.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 48,
                          top: 4,
                          bottom: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.checklist_rounded,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${subtasks.where((s) => s.isDone).length}/${subtasks.length}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Footer: Due Date, Repeat icon, Linked Note tag
                    Padding(
                      padding: const EdgeInsets.only(left: 48, top: 4),
                      child: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (task.dueAt != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.event_outlined,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM d').format(task.dueAt!),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          if (task.repeatRule != null)
                            Icon(
                              Icons.repeat_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          if (task.noteId != null && task.noteId!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.note_alt_outlined,
                                  size: 14,
                                  color: theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Note',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAgendaView(
    List<TaskModel> tasks,
    ThemeData theme,
    AppLocalizations? l10n,
  ) {
    final tasksWithDate = tasks.where((t) => t.dueAt != null).toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));

    if (tasksWithDate.isEmpty) {
      return const Center(child: Text('No upcoming scheduled tasks.'));
    }

    final groups = <String, List<TaskModel>>{};
    for (final t in tasksWithDate) {
      final key = DateFormat('EEEE, MMM d, yyyy').format(t.dueAt!);
      groups.putIfAbsent(key, () => []).add(t);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              entry.key,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          for (final t in entry.value)
            Card(
              child: ListTile(
                leading: Checkbox(
                  value: t.isDone,
                  onChanged: (_) =>
                      ref.read(tasksRepositoryProvider).completeTask(t),
                ),
                title: Text(t.title),
                subtitle: t.hasTime
                    ? Text(DateFormat('h:mm a').format(t.dueAt!))
                    : null,
                onTap: () => context.push('/task/${t.id}'),
              ),
            ),
        ],
      ],
    );
  }
}
