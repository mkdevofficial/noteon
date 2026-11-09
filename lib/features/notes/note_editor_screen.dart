import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteon/core/constants/app_constants.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/data/models/note_model.dart';
import 'package:noteon/data/models/task_model.dart';
import 'package:noteon/data/providers/repository_providers.dart';
import 'package:noteon/features/export_import/export_import_service.dart';
import 'package:noteon/features/notes/version_history_sheet.dart';
import 'package:noteon/features/settings/app_lock_service.dart';
import 'package:noteon/features/sharing/share_document_dialog.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final String initialType;

  const NoteEditorScreen({super.key, this.noteId, this.initialType = 'text'});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late quill.QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();

  NoteModel? _existingNote;
  bool _isLoading = true;
  String _noteType = 'text';
  int _noteColor = 0xFFFFFFFF;
  bool _isPinned = false;
  bool _isArchived = false;
  bool _isLocked = false;
  List<String> _labelIds = [];
  String? _folderId;
  DateTime? _reminderAt;

  // Checklist items if type == 'checklist'
  final List<Map<String, dynamic>> _checklistItems = [];

  Timer? _debounceTimer;
  int _wordCount = 0;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _quillController = quill.QuillController.basic();
    _noteType = widget.initialType;

    _titleController.addListener(_onContentChanged);
    _quillController.addListener(_onQuillChanged);

    _loadNoteData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.removeListener(_onContentChanged);
    _titleController.dispose();
    _quillController.removeListener(_onQuillChanged);
    _quillController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadNoteData() async {
    if (widget.noteId != null &&
        widget.noteId!.isNotEmpty &&
        widget.noteId != 'new') {
      final repo = ref.read(notesRepositoryProvider);
      final note = await repo.getNoteById(widget.noteId!);
      if (note != null) {
        _existingNote = note;
        _noteType = note.type;
        _noteColor = note.color;
        _isPinned = note.pinned;
        _isArchived = note.archived;
        _isLocked = note.lockedLocalOnly;
        _labelIds = List.from(note.labelIds);
        _folderId = note.folderId;
        _reminderAt = note.reminderAt;

        _titleController.text = note.title;

        if (note.type == 'checklist') {
          try {
            final decoded = json.decode(note.bodyDelta);
            if (decoded is List) {
              _checklistItems.clear();
              for (final item in decoded) {
                if (item is Map) {
                  _checklistItems.add(Map<String, dynamic>.from(item));
                }
              }
            }
          } catch (_) {}
        } else if (note.bodyDelta.isNotEmpty) {
          try {
            final deltaJson = json.decode(note.bodyDelta);
            final doc = quill.Document.fromJson(deltaJson);
            _quillController = quill.QuillController(
              document: doc,
              selection: const TextSelection.collapsed(offset: 0),
            );
            _quillController.addListener(_onQuillChanged);
          } catch (_) {}
        }
      }
    }
    _calculateCounts();
    setState(() => _isLoading = false);
  }

  void _onContentChanged() {
    _calculateCounts();
    _triggerDebouncedSave();
  }

  void _onQuillChanged() {
    _calculateCounts();
    _triggerDebouncedSave();
  }

  void _calculateCounts() {
    String text = '';
    if (_noteType == 'checklist') {
      text = _checklistItems.map((e) => e['text'] ?? '').join(' ');
    } else {
      text = _quillController.document.toPlainText();
    }
    final trimmed = text.trim();
    final words = trimmed.isEmpty ? 0 : trimmed.split(RegExp(r'\s+')).length;
    setState(() {
      _charCount = trimmed.length;
      _wordCount = words;
    });
  }

  void _triggerDebouncedSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(AppConstants.kSaveDebounce, () {
      _saveNote();
    });
  }

  Future<void> _saveNote() async {
    final user =
        ref.read(authStateProvider).valueOrNull ??
        ref.read(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? 'guest_user';

    String bodyDeltaStr = '';
    String plainTextStr = '';

    if (_noteType == 'checklist') {
      bodyDeltaStr = json.encode(_checklistItems);
      plainTextStr = _checklistItems
          .map(
            (e) => '${(e['done'] == true) ? "[x]" : "[ ]"} ${e['text'] ?? ""}',
          )
          .join('\n');
    } else {
      final deltaJson = _quillController.document.toDelta().toJson();
      bodyDeltaStr = json.encode(deltaJson);
      plainTextStr = _quillController.document.toPlainText().trim();
    }

    final repo = ref.read(notesRepositoryProvider);

    if (_existingNote == null) {
      // Create new note
      final newNote = NoteModel(
        id: '',
        ownerId: uid,
        memberIds: [uid],
        roles: {uid: 'owner'},
        type: _noteType,
        title: _titleController.text.trim(),
        bodyDelta: bodyDeltaStr,
        plainText: plainTextStr,
        color: _noteColor,
        pinned: _isPinned,
        archived: _isArchived,
        lockedLocalOnly: _isLocked,
        labelIds: _labelIds,
        folderId: _folderId,
        reminderAt: _reminderAt,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final res = await repo.createNote(newNote);
      if (res.isSuccess && res.dataOrNull != null) {
        _existingNote = res.dataOrNull;
      }
    } else {
      // Update existing note
      final updated = _existingNote!.copyWith(
        type: _noteType,
        title: _titleController.text.trim(),
        bodyDelta: bodyDeltaStr,
        plainText: plainTextStr,
        color: _noteColor,
        pinned: _isPinned,
        archived: _isArchived,
        lockedLocalOnly: _isLocked,
        labelIds: _labelIds,
        folderId: _folderId,
        reminderAt: _reminderAt,
        updatedAt: DateTime.now(),
      );
      await repo.updateNote(updated, authorId: uid);
      _existingNote = updated;
    }
  }

  void _applyTemplate(String templateKey) {
    if (_noteType != 'text') {
      setState(() => _noteType = 'text');
    }
    String templateDelta = '';
    String title = '';

    switch (templateKey) {
      case 'meeting':
        title = 'Meeting: Team Sync';
        templateDelta = json.encode([
          {
            "insert": "Meeting Notes\n",
            "attributes": {"header": 1},
          },
          {
            "insert": "Date: ",
            "attributes": {"bold": true},
          },
          {
            "insert":
                "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}\n",
          },
          {
            "insert": "Attendees: \n\n",
            "attributes": {"bold": true},
          },
          {
            "insert": "Agenda\n",
            "attributes": {"header": 2},
          },
          {"insert": "1. Discussion topic\n2. Key decisions\n\n"},
          {
            "insert": "Action Items\n",
            "attributes": {"header": 2},
          },
          {"insert": "• Action item 1\n• Action item 2\n"},
        ]);
        break;
      case 'journal':
        title = 'Daily Reflection';
        templateDelta = json.encode([
          {
            "insert": "Daily Journal\n",
            "attributes": {"header": 1},
          },
          {
            "insert": "What went well today?\n",
            "attributes": {"bold": true},
          },
          {"insert": "• \n\n"},
          {
            "insert": "What could be improved?\n",
            "attributes": {"bold": true},
          },
          {"insert": "• \n\n"},
          {
            "insert": "Daily Gratitude:\n",
            "attributes": {"bold": true},
          },
          {"insert": "• \n"},
        ]);
        break;
      case 'project':
        title = 'Project Plan';
        templateDelta = json.encode([
          {
            "insert": "Project Scope & Goals\n",
            "attributes": {"header": 1},
          },
          {
            "insert": "Objective:\n",
            "attributes": {"bold": true},
          },
          {"insert": "Define the primary outcome here.\n\n"},
          {
            "insert": "Milestones:\n",
            "attributes": {"header": 2},
          },
          {
            "insert": "1. Milestone 1 - Discovery\n2. Milestone 2 - Execution\n3. Milestone 3 - Launch\n",
          },
        ]);
        break;
      case 'shopping':
        setState(() {
          _noteType = 'checklist';
          _titleController.text = 'Shopping List';
          _checklistItems.clear();
          _checklistItems.addAll([
            {'text': 'Milk', 'done': false},
            {'text': 'Bread', 'done': false},
            {'text': 'Fresh vegetables', 'done': false},
            {'text': 'Olive oil', 'done': false},
          ]);
        });
        _onContentChanged();
        return;
    }

    _titleController.text = title;
    try {
      final doc = quill.Document.fromJson(json.decode(templateDelta));
      setState(() {
        _quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      });
      _quillController.addListener(_onQuillChanged);
    } catch (_) {}
    _onContentChanged();
  }

  void _showColorPicker() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = isDark
        ? AppConstants.noteColorsDark
        : AppConstants.noteColorsLight;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Note Color',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in palette)
                  InkWell(
                    onTap: () {
                      setState(() => _noteColor = c.toARGB32());
                      _triggerDebouncedSave();
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _noteColor == c.toARGB32()
                              ? theme.colorScheme.primary
                              : Colors.grey.withValues(alpha: 0.3),
                          width: _noteColor == c.toARGB32() ? 3 : 1,
                        ),
                      ),
                      child: _noteColor == c.toARGB32()
                          ? Icon(
                              Icons.check,
                              size: 20,
                              color:
                                  ThemeData.estimateBrightnessForColor(c) ==
                                      Brightness.light
                                  ? Colors.black87
                                  : Colors.white,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplatePicker() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: Text(l10n?.templateMeeting ?? 'Meeting Notes'),
              onTap: () {
                Navigator.pop(ctx);
                _applyTemplate('meeting');
              },
            ),
            ListTile(
              leading: const Icon(Icons.book_outlined),
              title: Text(l10n?.templateJournal ?? 'Daily Journal'),
              onTap: () {
                Navigator.pop(ctx);
                _applyTemplate('journal');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: Text(l10n?.templateShopping ?? 'Shopping List'),
              onTap: () {
                Navigator.pop(ctx);
                _applyTemplate('shopping');
              },
            ),
            ListTile(
              leading: const Icon(Icons.architecture_rounded),
              title: Text(l10n?.templateProject ?? 'Project Plan'),
              onTap: () {
                Navigator.pop(ctx);
                _applyTemplate('project');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLock() async {
    final success = await ref
        .read(appLockProvider.notifier)
        .authenticate(reason: 'Authenticate to protect or unlock note');
    if (success) {
      setState(() => _isLocked = !_isLocked);
      _triggerDebouncedSave();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLocked ? 'Note locked' : 'Note unlocked'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _convertChecklistItemToTask(String itemText) async {
    final user =
        ref.read(authStateProvider).valueOrNull ??
        ref.read(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? 'guest_user';

    final task = TaskModel(
      id: '',
      ownerId: uid,
      memberIds: [uid],
      roles: {uid: 'owner'},
      title: itemText,
      noteId: _existingNote?.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final repo = ref.read(tasksRepositoryProvider);
    await repo.createTask(task);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created task linked to this note: $itemText'),
          action: SnackBarAction(
            label: 'View Tasks',
            onPressed: () => context.go('/tasks'),
          ),
        ),
      );
    }
  }

  Future<void> _moveToTrash() async {
    if (_existingNote != null) {
      await ref.read(notesRepositoryProvider).trashNote(_existingNote!.id);
      if (mounted) {
        context.pop();
      }
    }
  }

  void _exportAsMarkdown() {
    if (_existingNote == null) return;
    final md = ExportImportService.exportNoteToMarkdown(_existingNote!);
    SharePlus.instance.share(
      ShareParams(text: md, subject: _existingNote!.title),
    );
  }

  Future<void> _exportAsPdf() async {
    if (_existingNote == null) return;
    final pdfBytes = await ExportImportService.exportNoteToPdf(_existingNote!);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${_existingNote!.title.replaceAll(" ", "_")}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    if (_noteColor != 0xFFFFFFFF && _noteColor != 0) {
      bg = Color(_noteColor);
    } else {
      bg = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    }

    final isLightBg =
        ThemeData.estimateBrightnessForColor(bg) == Brightness.light;
    final textColor = isLightBg ? Colors.black87 : Colors.white;

    final user =
        ref.read(authStateProvider).valueOrNull ??
        ref.read(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? 'guest_user';
    final linkedTasksStream = _existingNote != null
        ? ref
              .watch(tasksRepositoryProvider)
              .watchTasks(uid: uid, noteId: _existingNote!.id)
        : null;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: _isPinned ? theme.colorScheme.primary : null,
            ),
            tooltip: 'Pin Note',
            onPressed: () {
              setState(() => _isPinned = !_isPinned);
              _triggerDebouncedSave();
            },
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Color',
            onPressed: _showColorPicker,
          ),
          IconButton(
            icon: Icon(
              _isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: _isLocked ? Colors.amber[700] : null,
            ),
            tooltip: 'Lock Note',
            onPressed: _toggleLock,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) async {
              switch (val) {
                case 'templates':
                  _showTemplatePicker();
                  break;
                case 'share_collab':
                  if (_existingNote != null) {
                    ShareDocumentDialog.show(
                      context: context,
                      collection: 'notes',
                      documentId: _existingNote!.id,
                      roles: _existingNote!.roles,
                    );
                  }
                  break;
                case 'history':
                  if (_existingNote != null) {
                    VersionHistorySheet.show(
                      context,
                      noteId: _existingNote!.id,
                      onRestore: (snapshot) {
                        setState(() {
                          _titleController.text = snapshot.title;
                          if (snapshot.bodyDelta.isNotEmpty) {
                            try {
                              final doc = quill.Document.fromJson(
                                json.decode(snapshot.bodyDelta),
                              );
                              _quillController = quill.QuillController(
                                document: doc,
                                selection: const TextSelection.collapsed(
                                  offset: 0,
                                ),
                              );
                              _quillController.addListener(_onQuillChanged);
                            } catch (_) {}
                          }
                        });
                        _triggerDebouncedSave();
                      },
                    );
                  }
                  break;
                case 'export_pdf':
                  _exportAsPdf();
                  break;
                case 'export_md':
                  _exportAsMarkdown();
                  break;
                case 'share_text':
                  if (_existingNote != null) {
                    SharePlus.instance.share(
                      ShareParams(
                        text:
                            '${_existingNote!.title}\n\n${_existingNote!.plainText}',
                      ),
                    );
                  }
                  break;
                case 'toggle_type':
                  setState(() {
                    _noteType = _noteType == 'checklist' ? 'text' : 'checklist';
                  });
                  _onContentChanged();
                  break;
                case 'trash':
                  _moveToTrash();
                  break;
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'toggle_type',
                child: Text(
                  _noteType == 'checklist'
                      ? 'Convert to Text'
                      : 'Convert to Checklist',
                ),
              ),
              const PopupMenuItem(value: 'templates', child: Text('Templates')),
              if (_existingNote != null) ...[
                const PopupMenuItem(
                  value: 'share_collab',
                  child: Text('Collaborate (Share)'),
                ),
                const PopupMenuItem(
                  value: 'history',
                  child: Text('Version History'),
                ),
                const PopupMenuItem(
                  value: 'export_pdf',
                  child: Text('Export PDF'),
                ),
                const PopupMenuItem(
                  value: 'export_md',
                  child: Text('Export Markdown'),
                ),
                const PopupMenuItem(
                  value: 'share_text',
                  child: Text('Share as Text'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'trash',
                  child: Text(
                    'Move to Trash',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Note Title Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _titleController,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            // Rich text toolbar (if type == 'text')
            if (_noteType == 'text')
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black26
                      : Colors.white.withValues(alpha: 0.8),
                  border: Border(
                    top: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: quill.QuillSimpleToolbar(
                  controller: _quillController,
                  config: const quill.QuillSimpleToolbarConfig(
                    multiRowsDisplay: false,
                    showFontFamily: false,
                    showFontSize: false,
                    showSubscript: false,
                    showSuperscript: false,
                    showSearchButton: false,
                    showInlineCode: true,
                  ),
                ),
              ),

            // Note Content (Checklist or Rich Text)
            Expanded(
              child: _noteType == 'checklist'
                  ? _buildChecklistEditor(theme, textColor)
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: quill.QuillEditor.basic(
                        controller: _quillController,
                        focusNode: _editorFocusNode,
                        config: quill.QuillEditorConfig(
                          placeholder: 'Start typing note...',
                          autoFocus: false,
                          expands: true,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
            ),

            // Linked Tasks Live Section (if note has linked tasks)
            if (linkedTasksStream != null)
              StreamBuilder<List<TaskModel>>(
                stream: linkedTasksStream,
                builder: (context, snapshot) {
                  final tasks = snapshot.data ?? [];
                  if (tasks.isEmpty) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.link_rounded, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Linked Tasks (${tasks.length})',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        for (final t in tasks.take(3))
                          Row(
                            children: [
                              Checkbox(
                                value: t.isDone,
                                onChanged: (_) {
                                  ref
                                      .read(tasksRepositoryProvider)
                                      .completeTask(t);
                                },
                              ),
                              Expanded(
                                child: Text(
                                  t.title,
                                  style: TextStyle(
                                    decoration: t.isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),

            // Bottom Word / Character Count Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_wordCount words • $_charCount characters',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                  ),
                  if (_existingNote != null)
                    Text(
                      'Saved',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistEditor(ThemeData theme, Color textColor) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        for (var i = 0; i < _checklistItems.length; i++) ...[
          Dismissible(
            key: ValueKey('item_$i'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: AlignmentDirectional.centerEnd,
              padding: const EdgeInsets.only(right: 16),
              color: Colors.red[300],
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              setState(() {
                _checklistItems.removeAt(i);
              });
              _onContentChanged();
            },
            child: Row(
              children: [
                Checkbox(
                  value: _checklistItems[i]['done'] as bool? ?? false,
                  onChanged: (val) {
                    setState(() {
                      _checklistItems[i]['done'] = val ?? false;
                    });
                    _onContentChanged();
                  },
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: _checklistItems[i]['text'] as String? ?? '',
                    style: TextStyle(
                      color: textColor,
                      decoration: (_checklistItems[i]['done'] == true)
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      _checklistItems[i]['text'] = val;
                      _onContentChanged();
                    },
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, size: 18),
                  onSelected: (val) {
                    if (val == 'convert_to_task') {
                      _convertChecklistItemToTask(
                        _checklistItems[i]['text'] ?? '',
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'convert_to_task',
                      child: Text('Convert to Task'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        TextButton.icon(
          onPressed: () {
            setState(() {
              _checklistItems.add({'text': '', 'done': false});
            });
            _onContentChanged();
          },
          icon: const Icon(Icons.add),
          label: const Text('Add list item'),
        ),
      ],
    );
  }
}
