import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/data/models/folder_model.dart';
import 'package:noteon/data/models/label_model.dart';
import 'package:noteon/data/models/note_model.dart';
import 'package:noteon/data/providers/repository_providers.dart';
import 'package:noteon/features/home/sync_status_indicator.dart';
import 'package:noteon/features/notes/note_card_widget.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  NoteViewMode _viewMode = NoteViewMode.grid;
  String _sortBy = 'modified'; // 'modified', 'created', 'title'
  String? _selectedLabelId;
  String? _selectedFolderId;

  void _showNoteActions(NoteModel note) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(notesRepositoryProvider);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                note.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              ),
              title: Text(note.pinned ? 'Unpin' : (l10n?.pinned ?? 'Pin')),
              onTap: () {
                Navigator.pop(ctx);
                repo.updateNote(note.copyWith(pinned: !note.pinned));
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: Text(l10n?.archive ?? 'Archive'),
              onTap: () {
                Navigator.pop(ctx);
                repo.updateNote(note.copyWith(archived: true));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Note archived'),
                    action: SnackBarAction(
                      label: l10n?.undo ?? 'Undo',
                      onPressed: () {
                        repo.updateNote(note.copyWith(archived: false));
                      },
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: Text(l10n?.duplicate ?? 'Duplicate'),
              onTap: () {
                Navigator.pop(ctx);
                final dup = NoteModel(
                  id: '',
                  ownerId: note.ownerId,
                  memberIds: note.memberIds,
                  roles: note.roles,
                  type: note.type,
                  title: '${note.title} (Copy)',
                  bodyDelta: note.bodyDelta,
                  plainText: note.plainText,
                  color: note.color,
                  pinned: false,
                  archived: false,
                  labelIds: note.labelIds,
                  folderId: note.folderId,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                repo.createNote(dup);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
              ),
              title: Text(
                l10n?.delete ?? 'Delete',
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                repo.trashNote(note.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n?.noteDeleted ?? 'Note moved to trash'),
                    action: SnackBarAction(
                      label: l10n?.undo ?? 'Undo',
                      onPressed: () => repo.restoreNote(note.id),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
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

    final notesStream = ref.watch(notesRepositoryProvider).watchNotes(uid: uid);
    final labelsStream = ref
        .watch(labelsRepositoryProvider)
        .watchLabels(uid: uid);
    final foldersStream = ref
        .watch(foldersRepositoryProvider)
        .watchFolders(uid: uid);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.notesTitle ?? 'Notes',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          const SyncStatusIndicator(),
          // View Mode Selector
          IconButton(
            icon: Icon(
              _viewMode == NoteViewMode.grid
                  ? Icons.view_agenda_outlined
                  : _viewMode == NoteViewMode.list
                  ? Icons.table_rows_outlined
                  : Icons.grid_view_rounded,
            ),
            tooltip: 'Toggle View',
            onPressed: () {
              setState(() {
                _viewMode = switch (_viewMode) {
                  NoteViewMode.grid => NoteViewMode.list,
                  NoteViewMode.list => NoteViewMode.compact,
                  NoteViewMode.compact => NoteViewMode.grid,
                };
              });
            },
          ),
          // Drawer / Extra menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              switch (val) {
                case 'sort_modified':
                  setState(() => _sortBy = 'modified');
                  break;
                case 'sort_created':
                  setState(() => _sortBy = 'created');
                  break;
                case 'sort_title':
                  setState(() => _sortBy = 'title');
                  break;
                case 'archive':
                  context.push('/archive');
                  break;
                case 'trash':
                  context.push('/trash');
                  break;
                case 'labels':
                  context.push('/labels');
                  break;
                case 'folders':
                  context.push('/folders');
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'sort_modified',
                child: Text('Sort by Modified'),
              ),
              const PopupMenuItem(
                value: 'sort_created',
                child: Text('Sort by Created'),
              ),
              const PopupMenuItem(
                value: 'sort_title',
                child: Text('Sort by Title'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'archive',
                child: Text(l10n?.archive ?? 'Archive'),
              ),
              PopupMenuItem(
                value: 'trash',
                child: Text(l10n?.trash ?? 'Trash'),
              ),
              PopupMenuItem(
                value: 'labels',
                child: Text(l10n?.labels ?? 'Labels'),
              ),
              PopupMenuItem(
                value: 'folders',
                child: Text(l10n?.folders ?? 'Folders'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<LabelModel>>(
          stream: labelsStream,
          builder: (context, labelsSnap) {
            final allLabels = labelsSnap.data ?? [];

            return StreamBuilder<List<FolderModel>>(
              stream: foldersStream,
              builder: (context, foldersSnap) {
                final allFolders = foldersSnap.data ?? [];

                return StreamBuilder<List<NoteModel>>(
                  stream: notesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var notes = snapshot.data ?? [];

                    // Apply active label/folder filter
                    if (_selectedLabelId != null) {
                      notes = notes
                          .where((n) => n.labelIds.contains(_selectedLabelId))
                          .toList();
                    }
                    if (_selectedFolderId != null) {
                      notes = notes
                          .where((n) => n.folderId == _selectedFolderId)
                          .toList();
                    }

                    // Apply sort
                    if (_sortBy == 'title') {
                      notes.sort(
                        (a, b) => a.title.toLowerCase().compareTo(
                          b.title.toLowerCase(),
                        ),
                      );
                    } else if (_sortBy == 'created') {
                      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    }

                    if (notes.isEmpty &&
                        _selectedLabelId == null &&
                        _selectedFolderId == null) {
                      return _buildEmptyNotesState(theme, l10n);
                    }

                    final pinnedNotes = notes.where((n) => n.pinned).toList();
                    final otherNotes = notes.where((n) => !n.pinned).toList();

                    return Column(
                      children: [
                        // Filter Chips row (All, Folders, Labels)
                        _buildFilterChipsRow(allLabels, allFolders),

                        // Notes Content List/Grid
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              // Reactive listener refreshes automatically
                            },
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              children: [
                                if (pinnedNotes.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      l10n?.pinned ?? 'Pinned',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                  _buildNotesLayout(pinnedNotes, allLabels),
                                  const SizedBox(height: 16),
                                ],
                                if (otherNotes.isNotEmpty &&
                                    pinnedNotes.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      l10n?.others ?? 'Others',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                                if (otherNotes.isNotEmpty)
                                  _buildNotesLayout(otherNotes, allLabels),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChipsRow(
    List<LabelModel> labels,
    List<FolderModel> folders,
  ) {
    if (labels.isEmpty && folders.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _selectedLabelId == null && _selectedFolderId == null,
            onSelected: (_) {
              setState(() {
                _selectedLabelId = null;
                _selectedFolderId = null;
              });
            },
          ),
          for (final f in folders) ...[
            const SizedBox(width: 8),
            FilterChip(
              avatar: const Icon(Icons.folder_outlined, size: 16),
              label: Text(f.name),
              selected: _selectedFolderId == f.id,
              onSelected: (selected) {
                setState(() {
                  _selectedFolderId = selected ? f.id : null;
                });
              },
            ),
          ],
          for (final lb in labels) ...[
            const SizedBox(width: 8),
            FilterChip(
              avatar: const Icon(Icons.label_outline, size: 16),
              label: Text('#${lb.name}'),
              selected: _selectedLabelId == lb.id,
              onSelected: (selected) {
                setState(() {
                  _selectedLabelId = selected ? lb.id : null;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesLayout(
    List<NoteModel> notesList,
    List<LabelModel> allLabels,
  ) {
    final repo = ref.read(notesRepositoryProvider);

    if (_viewMode == NoteViewMode.grid) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: notesList.length,
        itemBuilder: (context, index) {
          final note = notesList[index];
          return NoteCardWidget(
            note: note,
            viewMode: _viewMode,
            allLabels: allLabels,
            onTap: () => context.push('/note/${note.id}'),
            onLongPress: () => _showNoteActions(note),
            onTogglePin: () =>
                repo.updateNote(note.copyWith(pinned: !note.pinned)),
            onColorChanged: (c) => repo.updateNote(note.copyWith(color: c)),
            onTrash: () => repo.trashNote(note.id),
            onArchive: () => repo.updateNote(note.copyWith(archived: true)),
          );
        },
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: notesList.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final note = notesList[index];
        return NoteCardWidget(
          note: note,
          viewMode: _viewMode,
          allLabels: allLabels,
          onTap: () => context.push('/note/${note.id}'),
          onLongPress: () => _showNoteActions(note),
          onTogglePin: () =>
              repo.updateNote(note.copyWith(pinned: !note.pinned)),
          onColorChanged: (c) => repo.updateNote(note.copyWith(color: c)),
          onTrash: () => repo.trashNote(note.id),
          onArchive: () => repo.updateNote(note.copyWith(archived: true)),
        );
      },
    );
  }

  Widget _buildEmptyNotesState(ThemeData theme, AppLocalizations? l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.4,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.note_add_rounded,
                size: 50,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.emptyNotesTitle ?? 'No notes yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.emptyNotesSubtitle ?? 'Tap + below to capture your thoughts, rich notes, or checklists.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
