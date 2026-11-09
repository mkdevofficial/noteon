import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/core/utils/arabic_search_normalizer.dart';
import 'package:noteon/data/models/note_model.dart';
import 'package:noteon/data/models/task_model.dart';
import 'package:noteon/data/providers/repository_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _filterType = 'all'; // 'all', 'notes', 'tasks'
  final List<String> _recentSearches = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    final trimmed = query.trim();
    if (trimmed.isNotEmpty && !_recentSearches.contains(trimmed)) {
      setState(() {
        _recentSearches.insert(0, trimmed);
        if (_recentSearches.length > 5) _recentSearches.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final query = _searchController.text.trim();

    final user =
        ref.watch(authStateProvider).valueOrNull ??
        ref.read(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? 'guest_user';

    final notesStream = ref.watch(notesRepositoryProvider).watchNotes(uid: uid);
    final tasksStream = ref.watch(tasksRepositoryProvider).watchTasks(uid: uid);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: false,
          textInputAction: TextInputAction.search,
          onSubmitted: _onSearchSubmitted,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText:
                l10n?.searchNotesAndTasks ?? 'Search notes, tasks, tags...',
            border: InputBorder.none,
            filled: false,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills (All, Notes only, Tasks only)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _filterType == 'all',
                    onSelected: (_) => setState(() => _filterType = 'all'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.note_alt_outlined, size: 16),
                    label: Text(l10n?.notesTitle ?? 'Notes'),
                    selected: _filterType == 'notes',
                    onSelected: (_) => setState(() => _filterType = 'notes'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                    ),
                    label: Text(l10n?.tasksTitle ?? 'Tasks'),
                    selected: _filterType == 'tasks',
                    onSelected: (_) => setState(() => _filterType = 'tasks'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // If query is empty, show recent searches
            if (query.isEmpty) ...[
              if (_recentSearches.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'Recent Searches',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final s in _recentSearches)
                      ActionChip(
                        avatar: const Icon(Icons.history, size: 16),
                        label: Text(s),
                        onPressed: () {
                          _searchController.text = s;
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ],
              Expanded(
                child: Center(
                  child: Text(
                    'Search anything with instant Arabic & English support',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ] else ...[
              // Live Results with Arabic Normalizer
              Expanded(
                child: StreamBuilder<List<NoteModel>>(
                  stream: notesStream,
                  builder: (context, noteSnap) {
                    final notes = noteSnap.data ?? [];

                    return StreamBuilder<List<TaskModel>>(
                      stream: tasksStream,
                      builder: (context, taskSnap) {
                        final tasks = taskSnap.data ?? [];

                        // Filter notes with ArabicSearchNormalizer
                        final matchingNotes =
                            (_filterType == 'all' || _filterType == 'notes')
                            ? notes.where((n) {
                                return ArabicSearchNormalizer.matches(
                                      n.title,
                                      query,
                                    ) ||
                                    ArabicSearchNormalizer.matches(
                                      n.plainText,
                                      query,
                                    );
                              }).toList()
                            : <NoteModel>[];

                        // Filter tasks with ArabicSearchNormalizer
                        final matchingTasks =
                            (_filterType == 'all' || _filterType == 'tasks')
                            ? tasks.where((t) {
                                return ArabicSearchNormalizer.matches(
                                      t.title,
                                      query,
                                    ) ||
                                    ArabicSearchNormalizer.matches(
                                      t.description,
                                      query,
                                    );
                              }).toList()
                            : <TaskModel>[];

                        if (matchingNotes.isEmpty && matchingTasks.isEmpty) {
                          return Center(
                            child: Text(
                              'No results found for "$query"',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }

                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (matchingTasks.isNotEmpty) ...[
                              Text(
                                '${l10n?.tasksTitle ?? "Tasks"} (${matchingTasks.length})',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (final t in matchingTasks)
                                Card(
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.check_circle_outline,
                                    ),
                                    title: Text(t.title),
                                    subtitle: t.description.isNotEmpty
                                        ? Text(t.description)
                                        : null,
                                    onTap: () => context.push('/task/${t.id}'),
                                  ),
                                ),
                              const SizedBox(height: 16),
                            ],
                            if (matchingNotes.isNotEmpty) ...[
                              Text(
                                '${l10n?.notesTitle ?? "Notes"} (${matchingNotes.length})',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (final n in matchingNotes)
                                Card(
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.description_outlined,
                                    ),
                                    title: Text(
                                      n.title.isNotEmpty
                                          ? n.title
                                          : 'Untitled Note',
                                    ),
                                    subtitle: Text(
                                      n.plainText,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () => context.push('/note/${n.id}'),
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
            ],
          ],
        ),
      ),
    );
  }
}
