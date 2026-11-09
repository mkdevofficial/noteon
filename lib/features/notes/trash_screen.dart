import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/data/models/note_model.dart';
import 'package:noteon/data/providers/repository_providers.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final user =
        ref.watch(authStateProvider).valueOrNull ??
        ref.read(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? 'guest_user';

    final notesRepo = ref.watch(notesRepositoryProvider);
    final trashStream = notesRepo.watchNotes(uid: uid, trashed: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.trash ?? 'Trash'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: l10n?.emptyTrash ?? 'Empty Trash',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n?.emptyTrash ?? 'Empty Trash'),
                  content: const Text(
                    'Are you sure you want to permanently delete all items in Trash?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Empty Trash'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await notesRepo.purgeOldTrash(uid: uid);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.amber.withValues(alpha: 0.15),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n?.trashPurgeNotice ?? 'Notes in Trash will be automatically purged after 30 days.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<NoteModel>>(
                stream: trashStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final trashedNotes = snapshot.data ?? [];
                  if (trashedNotes.isEmpty) {
                    return Center(
                      child: Text(
                        'Trash is empty',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: trashedNotes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final note = trashedNotes[index];
                      final dateStr = note.trashedAt != null
                          ? DateFormat('MMM d, yyyy').format(note.trashedAt!)
                          : '';

                      return Card(
                        child: ListTile(
                          title: Text(
                            note.title.isNotEmpty
                                ? note.title
                                : 'Untitled Note',
                          ),
                          subtitle: Text('Deleted: $dateStr'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.restore_rounded),
                                tooltip: l10n?.restore ?? 'Restore',
                                onPressed: () {
                                  notesRepo.restoreNote(note.id);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_forever_rounded,
                                  color: Colors.red,
                                ),
                                tooltip:
                                    l10n?.deletePermanently ?? 'Delete Forever',
                                onPressed: () {
                                  notesRepo.deleteNote(note.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
