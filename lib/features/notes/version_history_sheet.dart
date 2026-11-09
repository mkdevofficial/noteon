import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/data/models/note_history_model.dart';
import 'package:noteon/data/providers/repository_providers.dart';

class VersionHistorySheet extends ConsumerWidget {
  final String noteId;
  final Function(NoteHistoryModel snapshot) onRestore;

  const VersionHistorySheet({
    super.key,
    required this.noteId,
    required this.onRestore,
  });

  static void show(
    BuildContext context, {
    required String noteId,
    required Function(NoteHistoryModel) onRestore,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VersionHistorySheet(noteId: noteId, onRestore: onRestore),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final historyStream = ref
        .watch(notesRepositoryProvider)
        .watchNoteHistory(noteId);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.versionHistory ?? 'Version History',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Previous snapshots of this note (last 10). You can restore any earlier version.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<NoteHistoryModel>>(
              stream: historyStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final versions = snapshot.data ?? [];
                if (versions.isEmpty) {
                  return Center(
                    child: Text(
                      'No previous versions saved yet.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: versions.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = versions[index];
                    final dateStr = DateFormat('MMM d, yyyy • h:mm a')
                        .format(item.savedAt);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      title: Text(
                        item.title.isNotEmpty ? item.title : 'Untitled',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: FilledButton.tonal(
                        onPressed: () {
                          Navigator.pop(context);
                          onRestore(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Version restored successfully!'),
                            ),
                          );
                        },
                        child: Text(l10n?.restoreVersion ?? 'Restore'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
