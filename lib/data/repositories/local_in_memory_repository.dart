import 'dart:async';

import 'package:noteon/core/errors/app_exception.dart';
import 'package:noteon/core/utils/recurrence_engine.dart';
import 'package:noteon/data/models/folder_model.dart';
import 'package:noteon/data/models/label_model.dart';
import 'package:noteon/data/models/note_history_model.dart';
import 'package:noteon/data/models/note_model.dart';
import 'package:noteon/data/models/task_list_model.dart';
import 'package:noteon/data/models/task_model.dart';
import 'package:noteon/data/models/user_model.dart';
import 'package:noteon/data/repositories/auth_repository.dart';
import 'package:noteon/data/repositories/folders_repository.dart';
import 'package:noteon/data/repositories/labels_repository.dart';
import 'package:noteon/data/repositories/notes_repository.dart';
import 'package:noteon/data/repositories/sharing_repository.dart';
import 'package:noteon/data/repositories/task_lists_repository.dart';
import 'package:noteon/data/repositories/tasks_repository.dart';
import 'package:uuid/uuid.dart';

class LocalDemoRepository
    implements
        AuthRepository,
        NotesRepository,
        TasksRepository,
        TaskListsRepository,
        LabelsRepository,
        FoldersRepository,
        SharingRepository {
  static final LocalDemoRepository instance = LocalDemoRepository();

  final _uuid = const Uuid();
  UserModel? _currentUser = UserModel(
    uid: 'demo_user_1',
    email: 'demo@noteon.app',
    displayName: 'Demo User',
    isAnonymous: false,
    createdAt: DateTime.now(),
  );

  final _authController = StreamController<UserModel?>.broadcast();
  final _notes = <String, NoteModel>{};
  final _noteHistory = <String, List<NoteHistoryModel>>{};
  final _notesController = StreamController<List<NoteModel>>.broadcast();

  final _tasks = <String, TaskModel>{};
  final _tasksController = StreamController<List<TaskModel>>.broadcast();

  final _taskLists = <String, TaskListModel>{};
  final _taskListsController =
      StreamController<List<TaskListModel>>.broadcast();

  final _labels = <String, LabelModel>{};
  final _labelsController = StreamController<List<LabelModel>>.broadcast();

  final _folders = <String, FolderModel>{};
  final _foldersController = StreamController<List<FolderModel>>.broadcast();

  LocalDemoRepository() {
    _populateSeedData();
  }

  void _populateSeedData() {
    final now = DateTime.now();

    // Default label
    final labelWork = LabelModel(
      id: 'label_work',
      ownerId: 'demo_user_1',
      name: 'work',
      color: 0xFF2A9D8F,
    );
    final labelPersonal = LabelModel(
      id: 'label_personal',
      ownerId: 'demo_user_1',
      name: 'personal',
      color: 0xFFE76F51,
    );
    _labels[labelWork.id] = labelWork;
    _labels[labelPersonal.id] = labelPersonal;

    // Default list
    final defaultList = TaskListModel(
      id: 'list_general',
      ownerId: 'demo_user_1',
      memberIds: ['demo_user_1'],
      roles: {'demo_user_1': 'owner'},
      name: 'My Tasks',
      color: 0xFF4A6572,
    );
    _taskLists[defaultList.id] = defaultList;

    // Welcome Note
    final welcomeNote = NoteModel(
      id: 'note_welcome',
      ownerId: 'demo_user_1',
      memberIds: ['demo_user_1'],
      roles: {'demo_user_1': 'owner'},
      title: 'Welcome to NoteOn! 📝',
      plainText: 'Welcome to NoteOn! Seamlessly combine rich-text notes with powerful task management, full offline sync, and instant collaboration.',
      bodyDelta: '[{"insert":"Welcome to NoteOn!\\n","attributes":{"header":1}},{"insert":"Seamlessly combine rich-text notes with powerful task management, full offline sync, and instant collaboration.\\n"}]',
      color: 0xFFFFF8E7,
      pinned: true,
      labelIds: [labelPersonal.id],
      createdAt: now.subtract(const Duration(hours: 1)),
      updatedAt: now,
    );
    _notes[welcomeNote.id] = welcomeNote;

    // Sample Task
    final sampleTask = TaskModel(
      id: 'task_welcome',
      ownerId: 'demo_user_1',
      memberIds: ['demo_user_1'],
      roles: {'demo_user_1': 'owner'},
      listId: defaultList.id,
      title: 'Explore NoteOn features',
      description: 'Check out the Kanban board, calendar view, natural-language quick add, and rich text editor!',
      status: 'todo',
      priority: 'high',
      dueAt: now.add(const Duration(days: 1)),
      hasTime: true,
      labelIds: [labelWork.id],
      noteId: welcomeNote.id,
      createdAt: now,
      updatedAt: now,
    );
    _tasks[sampleTask.id] = sampleTask;
  }

  // --- Auth Repository ---
  @override
  Stream<UserModel?> get authStateChanges => _authController.stream;

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<Result<UserModel>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _currentUser = UserModel(
      uid: 'demo_user_1',
      email: email,
      displayName: email.split('@').first,
      createdAt: DateTime.now(),
    );
    _authController.add(_currentUser);
    return Result.success(_currentUser!);
  }

  @override
  Future<Result<UserModel>> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _currentUser = UserModel(
      uid: 'demo_user_1',
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );
    _authController.add(_currentUser);
    return Result.success(_currentUser!);
  }

  @override
  Future<Result<UserModel>> signInWithGoogle() async {
    _currentUser = UserModel(
      uid: 'demo_user_google',
      email: 'google_user@noteon.app',
      displayName: 'Google User',
      createdAt: DateTime.now(),
    );
    _authController.add(_currentUser);
    return Result.success(_currentUser!);
  }

  @override
  Future<Result<UserModel>> signInAnonymously() async {
    _currentUser = UserModel(
      uid: 'demo_anonymous_${_uuid.v4().substring(0, 8)}',
      email: '',
      displayName: 'Guest',
      isAnonymous: true,
      createdAt: DateTime.now(),
    );
    _authController.add(_currentUser);
    return Result.success(_currentUser!);
  }

  @override
  Future<Result<UserModel>> upgradeAnonymousWithEmail({
    required String email,
    required String password,
  }) async {
    if (_currentUser == null) {
      return Result.failure(const AuthException('No user'));
    }
    _currentUser = _currentUser!.copyWith(email: email, isAnonymous: false);
    _authController.add(_currentUser);
    return Result.success(_currentUser!);
  }

  @override
  Future<Result<UserModel>> upgradeAnonymousWithGoogle() async {
    if (_currentUser == null) {
      return Result.failure(const AuthException('No user'));
    }
    _currentUser = _currentUser!.copyWith(
      email: 'upgraded_google@noteon.app',
      displayName: 'Upgraded User',
      isAnonymous: false,
    );
    _authController.add(_currentUser);
    return Result.success(_currentUser!);
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async =>
      Result.success(null);

  @override
  Future<Result<void>> updateDisplayName(String displayName) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(displayName: displayName);
      _authController.add(_currentUser);
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async => Result.success(null);

  @override
  Future<Result<void>> signOut() async {
    _currentUser = null;
    _authController.add(null);
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteAccount(String passwordOrConfirm) async {
    _notes.clear();
    _tasks.clear();
    _currentUser = null;
    _authController.add(null);
    return Result.success(null);
  }

  // --- Notes Repository ---
  @override
  Stream<List<NoteModel>> watchNotes({
    required String uid,
    bool? trashed,
    bool? archived,
  }) {
    final stream = _notesController.stream;
    // Emit initial
    scheduleMicrotask(() => _notifyNotes());
    return stream.map((all) {
      return all.where((n) {
        if (!n.memberIds.contains(uid)) return false;
        if (trashed != null) {
          if (trashed && !n.isTrashed) return false;
          if (!trashed && n.isTrashed) return false;
        } else if (n.isTrashed) {
          return false;
        }
        if (archived != null) {
          if (archived && !n.archived) return false;
          if (!archived && n.archived) return false;
        } else if (n.archived && trashed != true) {
          return false;
        }
        return true;
      }).toList()..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        if (a.order != b.order) return a.order.compareTo(b.order);
        return b.updatedAt.compareTo(a.updatedAt);
      });
    });
  }

  void _notifyNotes() {
    _notesController.add(_notes.values.toList());
  }

  @override
  Future<NoteModel?> getNoteById(String noteId) async => _notes[noteId];

  @override
  Future<Result<NoteModel>> createNote(NoteModel note) async {
    final id = note.id.isNotEmpty ? note.id : 'note_${_uuid.v4()}';
    final saved = note.copyWith(updatedAt: DateTime.now());
    _notes[id] = NoteModel(
      id: id,
      ownerId: saved.ownerId,
      memberIds: saved.memberIds,
      roles: saved.roles,
      type: saved.type,
      title: saved.title,
      bodyDelta: saved.bodyDelta,
      plainText: saved.plainText,
      color: saved.color,
      pinned: saved.pinned,
      archived: saved.archived,
      trashedAt: saved.trashedAt,
      labelIds: saved.labelIds,
      folderId: saved.folderId,
      reminderAt: saved.reminderAt,
      lockedLocalOnly: saved.lockedLocalOnly,
      order: saved.order,
      createdAt: saved.createdAt,
      updatedAt: saved.updatedAt,
      version: saved.version,
    );
    _notifyNotes();
    return Result.success(_notes[id]!);
  }

  @override
  Future<Result<void>> updateNote(NoteModel note, {String? authorId}) async {
    if (_notes.containsKey(note.id)) {
      final existing = _notes[note.id]!;
      // Save history
      await saveVersionSnapshot(
        note.id,
        NoteHistoryModel(
          id: 'v_${_uuid.v4()}',
          title: existing.title,
          bodyDelta: existing.bodyDelta,
          savedAt: existing.updatedAt,
          savedBy: authorId ?? existing.ownerId,
        ),
      );
    }
    _notes[note.id] = note.copyWith(
      version: note.version + 1,
      updatedAt: DateTime.now(),
    );
    _notifyNotes();
    return Result.success(null);
  }

  @override
  Future<Result<void>> trashNote(String noteId) async {
    if (_notes.containsKey(noteId)) {
      _notes[noteId] = _notes[noteId]!.copyWith(
        trashedAt: DateTime.now(),
        pinned: false,
        updatedAt: DateTime.now(),
      );
      _notifyNotes();
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> restoreNote(String noteId) async {
    if (_notes.containsKey(noteId)) {
      _notes[noteId] = _notes[noteId]!.copyWith(
        clearTrashedAt: true,
        updatedAt: DateTime.now(),
      );
      _notifyNotes();
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteNote(String noteId) async {
    _notes.remove(noteId);
    _noteHistory.remove(noteId);
    _notifyNotes();
    return Result.success(null);
  }

  @override
  Future<Result<void>> purgeOldTrash({required String uid}) async {
    _notes.removeWhere((k, v) => v.ownerId == uid && v.isTrashed);
    _notifyNotes();
    return Result.success(null);
  }

  @override
  Future<Result<void>> saveVersionSnapshot(
    String noteId,
    NoteHistoryModel snapshot,
  ) async {
    final list = _noteHistory.putIfAbsent(noteId, () => []);
    list.insert(0, snapshot);
    if (list.length > 10) {
      list.removeRange(10, list.length);
    }
    return Result.success(null);
  }

  @override
  Stream<List<NoteHistoryModel>> watchNoteHistory(String noteId) {
    return Stream.value(_noteHistory[noteId] ?? []);
  }

  @override
  Future<Result<void>> batchImportNotes(List<NoteModel> notes) async {
    for (final n in notes) {
      _notes[n.id] = n;
    }
    _notifyNotes();
    return Result.success(null);
  }

  // --- Tasks Repository ---
  @override
  Stream<List<TaskModel>> watchTasks({
    required String uid,
    String? listId,
    String? noteId,
  }) {
    scheduleMicrotask(() => _notifyTasks());
    return _tasksController.stream.map((all) {
      return all.where((t) {
        if (!t.memberIds.contains(uid)) return false;
        if (listId != null && t.listId != listId) return false;
        if (noteId != null && t.noteId != noteId) return false;
        return true;
      }).toList()..sort((a, b) {
        if (a.order != b.order) return a.order.compareTo(b.order);
        if (a.dueAt != null && b.dueAt != null) {
          return a.dueAt!.compareTo(b.dueAt!);
        }
        if (a.dueAt != null) return -1;
        if (b.dueAt != null) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    });
  }

  void _notifyTasks() {
    _tasksController.add(_tasks.values.toList());
  }

  @override
  Future<TaskModel?> getTaskById(String taskId) async => _tasks[taskId];

  @override
  Future<Result<TaskModel>> createTask(TaskModel task) async {
    final id = task.id.isNotEmpty ? task.id : 'task_${_uuid.v4()}';
    final saved = task.copyWith(updatedAt: DateTime.now());
    _tasks[id] = TaskModel(
      id: id,
      ownerId: saved.ownerId,
      memberIds: saved.memberIds,
      roles: saved.roles,
      listId: saved.listId,
      title: saved.title,
      description: saved.description,
      status: saved.status,
      priority: saved.priority,
      startAt: saved.startAt,
      dueAt: saved.dueAt,
      hasTime: saved.hasTime,
      remindAt: saved.remindAt,
      repeatRule: saved.repeatRule,
      labelIds: saved.labelIds,
      parentTaskId: saved.parentTaskId,
      noteId: saved.noteId,
      completedAt: saved.completedAt,
      order: saved.order,
      timeSpentSec: saved.timeSpentSec,
      createdAt: saved.createdAt,
      updatedAt: saved.updatedAt,
    );
    _notifyTasks();
    return Result.success(_tasks[id]!);
  }

  @override
  Future<Result<void>> updateTask(TaskModel task) async {
    _tasks[task.id] = task.copyWith(updatedAt: DateTime.now());
    _notifyTasks();
    return Result.success(null);
  }

  @override
  Future<Result<void>> completeTask(TaskModel task) async {
    final isDone = task.status != 'done';
    final now = DateTime.now();
    _tasks[task.id] = task.copyWith(
      status: isDone ? 'done' : 'todo',
      completedAt: isDone ? now : null,
      clearCompletedAt: !isDone,
      updatedAt: now,
    );

    // If completed a recurring task, create next instance
    if (isDone && task.repeatRule != null && task.dueAt != null) {
      final nextDue = RecurrenceEngine.computeNextDueDate(
        currentDueDate: task.dueAt!,
        rule: task.repeatRule!,
        completionDate: now,
      );
      if (nextDue != null) {
        final nextId = 'task_${_uuid.v4()}';
        _tasks[nextId] = task.copyWith(
          status: 'todo',
          dueAt: nextDue,
          clearCompletedAt: true,
          updatedAt: now,
        );
      }
    }
    _notifyTasks();
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteTask(String taskId) async {
    _tasks.remove(taskId);
    _tasks.removeWhere((k, v) => v.parentTaskId == taskId);
    _notifyTasks();
    return Result.success(null);
  }

  @override
  Future<Result<void>> bulkComplete(List<String> taskIds, bool isDone) async {
    for (final id in taskIds) {
      if (_tasks.containsKey(id)) {
        _tasks[id] = _tasks[id]!.copyWith(
          status: isDone ? 'done' : 'todo',
          completedAt: isDone ? DateTime.now() : null,
          clearCompletedAt: !isDone,
          updatedAt: DateTime.now(),
        );
      }
    }
    _notifyTasks();
    return Result.success(null);
  }

  @override
  Future<Result<void>> bulkDelete(List<String> taskIds) async {
    for (final id in taskIds) {
      _tasks.remove(id);
    }
    _notifyTasks();
    return Result.success(null);
  }

  @override
  Future<Result<void>> bulkMove(List<String> taskIds, String? listId) async {
    for (final id in taskIds) {
      if (_tasks.containsKey(id)) {
        _tasks[id] = _tasks[id]!.copyWith(
          listId: listId,
          clearListId: listId == null,
        );
      }
    }
    _notifyTasks();
    return Result.success(null);
  }

  @override
  Future<Result<void>> bulkSetDueDate(
    List<String> taskIds,
    DateTime? dueAt,
  ) async {
    for (final id in taskIds) {
      if (_tasks.containsKey(id)) {
        _tasks[id] = _tasks[id]!.copyWith(
          dueAt: dueAt,
          clearDueAt: dueAt == null,
        );
      }
    }
    _notifyTasks();
    return Result.success(null);
  }

  @override
  Future<Result<void>> bulkAddLabel(
    List<String> taskIds,
    String labelId,
  ) async {
    for (final id in taskIds) {
      if (_tasks.containsKey(id)) {
        final existing = _tasks[id]!.labelIds;
        if (!existing.contains(labelId)) {
          _tasks[id] = _tasks[id]!.copyWith(labelIds: [...existing, labelId]);
        }
      }
    }
    _notifyTasks();
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateTimeSpent(String taskId, int seconds) async {
    if (_tasks.containsKey(taskId)) {
      _tasks[taskId] = _tasks[taskId]!.copyWith(
        timeSpentSec: _tasks[taskId]!.timeSpentSec + seconds,
        updatedAt: DateTime.now(),
      );
      _notifyTasks();
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> batchImportTasks(List<TaskModel> tasks) async {
    for (final t in tasks) {
      _tasks[t.id] = t;
    }
    _notifyTasks();
    return Result.success(null);
  }

  // --- Task Lists ---
  @override
  Stream<List<TaskListModel>> watchTaskLists({required String uid}) {
    scheduleMicrotask(() => _notifyLists());
    return _taskListsController.stream.map(
      (all) => all.where((l) => l.memberIds.contains(uid)).toList(),
    );
  }

  void _notifyLists() => _taskListsController.add(_taskLists.values.toList());

  @override
  Future<Result<TaskListModel>> createTaskList(TaskListModel list) async {
    final id = list.id.isNotEmpty ? list.id : 'list_${_uuid.v4()}';
    _taskLists[id] = list.copyWith();
    _notifyLists();
    return Result.success(_taskLists[id]!);
  }

  @override
  Future<Result<void>> updateTaskList(TaskListModel list) async {
    _taskLists[list.id] = list;
    _notifyLists();
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteTaskList(String listId) async {
    _taskLists.remove(listId);
    _notifyLists();
    return Result.success(null);
  }

  // --- Labels ---
  @override
  Stream<List<LabelModel>> watchLabels({required String uid}) {
    scheduleMicrotask(() => _notifyLabels());
    return _labelsController.stream.map(
      (all) => all.where((l) => l.ownerId == uid).toList(),
    );
  }

  void _notifyLabels() => _labelsController.add(_labels.values.toList());

  @override
  Future<Result<LabelModel>> createLabel(LabelModel label) async {
    final id = label.id.isNotEmpty ? label.id : 'label_${_uuid.v4()}';
    _labels[id] = label.copyWith();
    _notifyLabels();
    return Result.success(_labels[id]!);
  }

  @override
  Future<Result<void>> updateLabel(LabelModel label) async {
    _labels[label.id] = label;
    _notifyLabels();
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteLabel(String labelId) async {
    _labels.remove(labelId);
    _notifyLabels();
    return Result.success(null);
  }

  // --- Folders ---
  @override
  Stream<List<FolderModel>> watchFolders({required String uid}) {
    scheduleMicrotask(() => _notifyFolders());
    return _foldersController.stream.map(
      (all) => all.where((f) => f.ownerId == uid).toList(),
    );
  }

  void _notifyFolders() => _foldersController.add(_folders.values.toList());

  @override
  Future<Result<FolderModel>> createFolder(FolderModel folder) async {
    final id = folder.id.isNotEmpty ? folder.id : 'folder_${_uuid.v4()}';
    _folders[id] = folder.copyWith();
    _notifyFolders();
    return Result.success(_folders[id]!);
  }

  @override
  Future<Result<void>> updateFolder(FolderModel folder) async {
    _folders[folder.id] = folder;
    _notifyFolders();
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteFolder(String folderId) async {
    _folders.remove(folderId);
    _notifyFolders();
    return Result.success(null);
  }

  // --- Sharing ---
  @override
  Future<Result<CollaboratorInfo>> shareDocumentByEmail({
    required String collection,
    required String documentId,
    required String targetEmail,
    required String role,
  }) async {
    final fakeUid = 'collab_${targetEmail.hashCode.abs()}';
    if (collection == 'notes' && _notes.containsKey(documentId)) {
      final n = _notes[documentId]!;
      _notes[documentId] = n.copyWith(
        memberIds: [...n.memberIds, fakeUid],
        roles: {...n.roles, fakeUid: role},
      );
      _notifyNotes();
    } else if (collection == 'taskLists' &&
        _taskLists.containsKey(documentId)) {
      final l = _taskLists[documentId]!;
      _taskLists[documentId] = l.copyWith(
        memberIds: [...l.memberIds, fakeUid],
        roles: {...l.roles, fakeUid: role},
      );
      _notifyLists();
    }
    return Result.success(
      CollaboratorInfo(
        uid: fakeUid,
        role: role,
        displayName: targetEmail.split('@').first,
        email: targetEmail,
      ),
    );
  }

  @override
  Future<Result<void>> updateCollaboratorRole({
    required String collection,
    required String documentId,
    required String targetUid,
    required String newRole,
  }) async {
    if (collection == 'notes' && _notes.containsKey(documentId)) {
      final n = _notes[documentId]!;
      _notes[documentId] = n.copyWith(roles: {...n.roles, targetUid: newRole});
      _notifyNotes();
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> revokeCollaboratorAccess({
    required String collection,
    required String documentId,
    required String targetUid,
  }) async {
    if (collection == 'notes' && _notes.containsKey(documentId)) {
      final n = _notes[documentId]!;
      final newMembers = List<String>.from(n.memberIds)..remove(targetUid);
      final newRoles = Map<String, String>.from(n.roles)..remove(targetUid);
      _notes[documentId] = n.copyWith(memberIds: newMembers, roles: newRoles);
      _notifyNotes();
    }
    return Result.success(null);
  }

  @override
  Future<List<CollaboratorInfo>> fetchCollaboratorProfiles({
    required Map<String, String> roles,
  }) async {
    return roles.entries.map((e) {
      return CollaboratorInfo(
        uid: e.key,
        role: e.value,
        displayName: e.key == 'demo_user_1'
            ? 'Demo User (You)'
            : 'User ${e.key.substring(0, 4)}',
        email: e.key == 'demo_user_1'
            ? 'demo@noteon.app'
            : 'collaborator@noteon.app',
      );
    }).toList();
  }
}
