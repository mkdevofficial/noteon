import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:noteon/core/constants/app_constants.dart';
import 'package:noteon/core/errors/app_exception.dart';
import 'package:noteon/core/utils/conflict_handler.dart';
import 'package:noteon/data/models/note_history_model.dart';
import 'package:noteon/data/models/note_model.dart';

abstract class NotesRepository {
  Stream<List<NoteModel>> watchNotes({
    required String uid,
    bool? trashed,
    bool? archived,
  });

  Future<NoteModel?> getNoteById(String noteId);

  Future<Result<NoteModel>> createNote(NoteModel note);

  Future<Result<void>> updateNote(NoteModel note, {String? authorId});

  Future<Result<void>> trashNote(String noteId);

  Future<Result<void>> restoreNote(String noteId);

  Future<Result<void>> deleteNote(String noteId);

  Future<Result<void>> purgeOldTrash({required String uid});

  Future<Result<void>> saveVersionSnapshot(
    String noteId,
    NoteHistoryModel snapshot,
  );

  Stream<List<NoteHistoryModel>> watchNoteHistory(String noteId);

  Future<Result<void>> batchImportNotes(List<NoteModel> notes);
}

class FirestoreNotesRepository implements NotesRepository {
  final FirebaseFirestore _firestore;

  FirestoreNotesRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notesRef =>
      _firestore.collection('notes');

  @override
  Stream<List<NoteModel>> watchNotes({
    required String uid,
    bool? trashed,
    bool? archived,
  }) {
    if (Firebase.apps.isEmpty) {
      return Stream.value([]);
    }

    Query<Map<String, dynamic>> query = _notesRef
        .where('memberIds', arrayContains: uid)
        .limit(300);

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NoteModel.fromFirestore(doc))
          .toList();

      return list.where((note) {
        if (trashed != null) {
          if (trashed && !note.isTrashed) return false;
          if (!trashed && note.isTrashed) return false;
        } else if (note.isTrashed) {
          return false; // Default: exclude trashed
        }

        if (archived != null) {
          if (archived && !note.archived) return false;
          if (!archived && note.archived) return false;
        } else if (note.archived && trashed != true) {
          return false; // Default: exclude archived from main list
        }

        return true;
      }).toList()..sort((a, b) {
        // Pinned first, then order, then updatedAt
        if (a.pinned != b.pinned) {
          return a.pinned ? -1 : 1;
        }
        if (a.order != b.order) {
          return a.order.compareTo(b.order);
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });
    });
  }

  @override
  Future<NoteModel?> getNoteById(String noteId) async {
    if (Firebase.apps.isEmpty) return null;
    try {
      final doc = await _notesRef.doc(noteId).get();
      if (!doc.exists || doc.data() == null) return null;
      return NoteModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<NoteModel>> createNote(NoteModel note) async {
    if (Firebase.apps.isEmpty) {
      return Result.success(note);
    }
    try {
      final docRef = note.id.isNotEmpty
          ? _notesRef.doc(note.id)
          : _notesRef.doc();
      final newNote = note.copyWith();
      await docRef.set(newNote.toFirestore());
      return Result.success(newNote);
    } catch (e) {
      return Result.failure(StorageException('Failed to create note: $e'));
    }
  }

  @override
  Future<Result<void>> updateNote(NoteModel note, {String? authorId}) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      final docRef = _notesRef.doc(note.id);

      // Conflict handling & version history snapshot
      final existingDoc = await docRef.get();
      if (existingDoc.exists && existingDoc.data() != null) {
        final remote = NoteModel.fromFirestore(existingDoc);

        final localPayload = NoteConflictPayload(
          id: note.id,
          title: note.title,
          bodyDelta: note.bodyDelta,
          version: note.version,
          updatedAt: note.updatedAt,
          authorId: authorId ?? note.ownerId,
        );

        final remotePayload = NoteConflictPayload(
          id: remote.id,
          title: remote.title,
          bodyDelta: remote.bodyDelta,
          version: remote.version,
          updatedAt: remote.updatedAt,
          authorId: remote.ownerId,
        );

        final resolution = ConflictHandler.resolveNoteConflict(
          local: localPayload,
          remote: remotePayload,
          baseVersion: note.version - 1,
        );

        // If an item needs to be archived into history to prevent silent overwrite
        if (resolution.itemToArchive != null) {
          final losing = resolution.itemToArchive!;
          await saveVersionSnapshot(
            note.id,
            NoteHistoryModel(
              id: '',
              title: losing.title,
              bodyDelta: losing.bodyDelta,
              savedAt: losing.updatedAt,
              savedBy: losing.authorId,
            ),
          );
        }
      }

      final updatedNote = note.copyWith(
        version: note.version + 1,
        updatedAt: DateTime.now(),
      );

      await docRef.update(updatedNote.toFirestore());
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed to update note: $e'));
    }
  }

  @override
  Future<Result<void>> trashNote(String noteId) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      await _notesRef.doc(noteId).update({
        'trashedAt': Timestamp.now(),
        'pinned': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed to trash note: $e'));
    }
  }

  @override
  Future<Result<void>> restoreNote(String noteId) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      await _notesRef.doc(noteId).update({
        'trashedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed to restore note: $e'));
    }
  }

  @override
  Future<Result<void>> deleteNote(String noteId) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      // Delete history subcollection docs first
      final historyDocs = await _notesRef
          .doc(noteId)
          .collection('history')
          .limit(20)
          .get();
      final batch = _firestore.batch();
      for (final h in historyDocs.docs) {
        batch.delete(h.reference);
      }
      batch.delete(_notesRef.doc(noteId));
      await batch.commit();
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        StorageException('Failed to permanently delete note: $e'),
      );
    }
  }

  @override
  Future<Result<void>> purgeOldTrash({required String uid}) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      final cutoff = DateTime.now().subtract(
        AppConstants.kTrashRetentionDuration,
      );
      final query = await _notesRef
          .where('ownerId', isEqualTo: uid)
          .where('trashedAt', isLessThanOrEqualTo: Timestamp.fromDate(cutoff))
          .limit(100)
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed to purge old trash: $e'));
    }
  }

  @override
  Future<Result<void>> saveVersionSnapshot(
    String noteId,
    NoteHistoryModel snapshot,
  ) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      final historyRef = _notesRef.doc(noteId).collection('history');
      await historyRef.add(snapshot.toMap());

      // Prune older than 10
      final query = await historyRef.orderBy('savedAt', descending: true).get();
      if (query.docs.length > AppConstants.kMaxVersionHistory) {
        final batch = _firestore.batch();
        for (
          var i = AppConstants.kMaxVersionHistory;
          i < query.docs.length;
          i++
        ) {
          batch.delete(query.docs[i].reference);
        }
        await batch.commit();
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed to save version: $e'));
    }
  }

  @override
  Stream<List<NoteHistoryModel>> watchNoteHistory(String noteId) {
    if (Firebase.apps.isEmpty) return Stream.value([]);
    return _notesRef
        .doc(noteId)
        .collection('history')
        .orderBy('savedAt', descending: true)
        .limit(AppConstants.kMaxVersionHistory)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => NoteHistoryModel.fromFirestore(d)).toList(),
        );
  }

  @override
  Future<Result<void>> batchImportNotes(List<NoteModel> notes) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      for (var i = 0; i < notes.length; i += AppConstants.kBatchSize) {
        final chunk = notes.sublist(
          i,
          i + AppConstants.kBatchSize > notes.length
              ? notes.length
              : i + AppConstants.kBatchSize,
        );
        final batch = _firestore.batch();
        for (final note in chunk) {
          final doc = note.id.isNotEmpty
              ? _notesRef.doc(note.id)
              : _notesRef.doc();
          batch.set(doc, note.toFirestore());
        }
        await batch.commit();
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Batch import failed: $e'));
    }
  }
}
