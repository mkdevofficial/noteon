import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/data/models/note_model.dart';
import 'package:noteon/data/models/task_list_model.dart';
import 'package:noteon/data/providers/repository_providers.dart';

class SharedWithMeScreen extends ConsumerWidget {
  const SharedWithMeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final user =
        ref.watch(authStateProvider).valueOrNull ??
        ref.read(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? 'guest_user';

    final notesStream = ref.watch(notesRepositoryProvider).watchNotes(uid: uid);
    final listsStream = ref
        .watch(taskListsRepositoryProvider)
        .watchTaskLists(uid: uid);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.sharedWithMe ?? 'Shared with me')),
      body: SafeArea(
        child: StreamBuilder<List<NoteModel>>(
          stream: notesStream,
          builder: (context, noteSnap) {
            final allNotes = noteSnap.data ?? [];
            final sharedNotes = allNotes
                .where((n) => n.ownerId != uid)
                .toList();

            return StreamBuilder<List<TaskListModel>>(
              stream: listsStream,
              builder: (context, listSnap) {
                final allLists = listSnap.data ?? [];
                final sharedLists = allLists
                    .where((l) => l.ownerId != uid)
                    .toList();

                if (sharedNotes.isEmpty && sharedLists.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_shared_outlined,
                            size: 64,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No shared items yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Notes and task lists shared with your email will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (sharedNotes.isNotEmpty) ...[
                      Text(
                        'Shared Notes',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final n in sharedNotes)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.note_alt_outlined),
                            title: Text(
                              n.title.isNotEmpty ? n.title : 'Untitled Note',
                            ),
                            subtitle: Text('Role: ${n.roles[uid] ?? "Viewer"}'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                            ),
                            onTap: () => context.push('/note/${n.id}'),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                    if (sharedLists.isNotEmpty) ...[
                      Text(
                        'Shared Projects',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final l in sharedLists)
                        Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(l.color),
                              radius: 12,
                            ),
                            title: Text(l.name),
                            subtitle: Text('Role: ${l.roles[uid] ?? "Viewer"}'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                            ),
                            onTap: () => context.go('/tasks'),
                          ),
                        ),
                    ],
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
