import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/data/models/note_model.dart';
import 'package:noteon/data/providers/repository_providers.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final user =
        ref.watch(authStateProvider).valueOrNull ??
        ref.read(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? 'guest_user';

    final notesRepo = ref.watch(notesRepositoryProvider);
    final archiveStream = notesRepo.watchNotes(uid: uid, archived: true);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.archive ?? 'Archive')),
      body: SafeArea(
        child: StreamBuilder<List<NoteModel>>(
          stream: archiveStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final archivedNotes = snapshot.data ?? [];
            if (archivedNotes.isEmpty) {
              return Center(
                child: Text(
                  'No archived notes',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: archivedNotes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final note = archivedNotes[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      note.title.isNotEmpty ? note.title : 'Untitled Note',
                    ),
                    subtitle: Text(
                      note.plainText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => context.push('/note/${note.id}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.unarchive_outlined),
                      tooltip: 'Unarchive',
                      onPressed: () {
                        notesRepo.updateNote(note.copyWith(archived: false));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Note unarchived')),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
