import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/data/models/task_model.dart';
import 'package:noteon/data/providers/repository_providers.dart';

class KanbanBoardView extends ConsumerWidget {
  final List<TaskModel> allTasks;

  const KanbanBoardView({super.key, required this.allTasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final todoTasks = allTasks
        .where((t) => t.status == 'todo' && !t.isSubtask)
        .toList();
    final inProgressTasks = allTasks
        .where((t) => t.status == 'in_progress' && !t.isSubtask)
        .toList();
    final doneTasks = allTasks
        .where((t) => t.status == 'done' && !t.isSubtask)
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKanbanColumn(
            context: context,
            ref: ref,
            title: l10n?.statusTodo ?? 'To Do',
            status: 'todo',
            tasks: todoTasks,
            accentColor: Colors.blueGrey,
          ),
          const SizedBox(width: 14),
          _buildKanbanColumn(
            context: context,
            ref: ref,
            title: l10n?.statusInProgress ?? 'In Progress',
            status: 'in_progress',
            tasks: inProgressTasks,
            accentColor: Colors.amber[700]!,
          ),
          const SizedBox(width: 14),
          _buildKanbanColumn(
            context: context,
            ref: ref,
            title: l10n?.statusDone ?? 'Done',
            status: 'done',
            tasks: doneTasks,
            accentColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String status,
    required List<TaskModel> tasks,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);

    return DragTarget<TaskModel>(
      onAcceptWithDetails: (details) {
        final task = details.data;
        if (task.status != status) {
          final updated = task.copyWith(
            status: status,
            completedAt: status == 'done' ? DateTime.now() : null,
            clearCompletedAt: status != 'done',
          );
          ref.read(tasksRepositoryProvider).updateTask(updated);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;

        return Container(
          width: 290,
          decoration: BoxDecoration(
            color: isHighlighted
                ? accentColor.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.35,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlighted
                  ? accentColor
                  : Colors.grey.withValues(alpha: 0.2),
              width: isHighlighted ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Column Cards
              if (tasks.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  alignment: Alignment.center,
                  child: Text(
                    'No tasks here',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final task = tasks[idx];
                    return _buildDraggableCard(context, ref, task);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggableCard(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
  ) {
    final theme = Theme.of(context);
    final isDone = task.status == 'done';

    return Draggable<TaskModel>(
      data: task,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 270,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            task.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCardContent(context, ref, task, isDone),
      ),
      child: _buildCardContent(context, ref, task, isDone),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
    bool isDone,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/task/${task.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: isDone,
                    visualDensity: VisualDensity.compact,
                    onChanged: (_) {
                      ref.read(tasksRepositoryProvider).completeTask(task);
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // Chips: Due date, Priority
              Row(
                children: [
                  if (task.dueAt != null) ...[
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
                    const SizedBox(width: 8),
                  ],
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
            ],
          ),
        ),
      ),
    );
  }
}
