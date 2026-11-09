import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:noteon/core/constants/app_constants.dart';
import 'package:noteon/core/errors/app_exception.dart';
import 'package:noteon/core/utils/recurrence_engine.dart';
import 'package:noteon/data/models/task_model.dart';

abstract class TasksRepository {
  Stream<List<TaskModel>> watchTasks({
    required String uid,
    String? listId,
    String? noteId,
  });

  Future<TaskModel?> getTaskById(String taskId);

  Future<Result<TaskModel>> createTask(TaskModel task);

  Future<Result<void>> updateTask(TaskModel task);

  Future<Result<void>> completeTask(TaskModel task);

  Future<Result<void>> deleteTask(String taskId);

  Future<Result<void>> bulkComplete(List<String> taskIds, bool isDone);

  Future<Result<void>> bulkDelete(List<String> taskIds);

  Future<Result<void>> bulkMove(List<String> taskIds, String? listId);

  Future<Result<void>> bulkSetDueDate(List<String> taskIds, DateTime? dueAt);

  Future<Result<void>> bulkAddLabel(List<String> taskIds, String labelId);

  Future<Result<void>> updateTimeSpent(String taskId, int seconds);

  Future<Result<void>> batchImportTasks(List<TaskModel> tasks);
}

class FirestoreTasksRepository implements TasksRepository {
  final FirebaseFirestore _firestore;

  FirestoreTasksRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      _firestore.collection('tasks');

  @override
  Stream<List<TaskModel>> watchTasks({
    required String uid,
    String? listId,
    String? noteId,
  }) {
    if (Firebase.apps.isEmpty) {
      return Stream.value([]);
    }

    Query<Map<String, dynamic>> query = _tasksRef
        .where('memberIds', arrayContains: uid)
        .limit(300);

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();

      return list.where((t) {
        if (listId != null && t.listId != listId) return false;
        if (noteId != null && t.noteId != noteId) return false;
        return true;
      }).toList()..sort((a, b) {
        if (a.order != b.order) {
          return a.order.compareTo(b.order);
        }
        if (a.dueAt != null && b.dueAt != null) {
          return a.dueAt!.compareTo(b.dueAt!);
        }
        if (a.dueAt != null) return -1;
        if (b.dueAt != null) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    });
  }

  @override
  Future<TaskModel?> getTaskById(String taskId) async {
    if (Firebase.apps.isEmpty) return null;
    try {
      final doc = await _tasksRef.doc(taskId).get();
      if (!doc.exists || doc.data() == null) return null;
      return TaskModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<TaskModel>> createTask(TaskModel task) async {
    if (Firebase.apps.isEmpty) return Result.success(task);
    try {
      final docRef = task.id.isNotEmpty
          ? _tasksRef.doc(task.id)
          : _tasksRef.doc();
      final newTask = task.copyWith();
      await docRef.set(newTask.toFirestore());
      return Result.success(newTask);
    } catch (e) {
      return Result.failure(StorageException('Failed to create task: $e'));
    }
  }

  @override
  Future<Result<void>> updateTask(TaskModel task) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      await _tasksRef.doc(task.id).update(task.toFirestore());
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed to update task: $e'));
    }
  }

  @override
  Future<Result<void>> completeTask(TaskModel task) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      final now = DateTime.now();
      final isNowDone = task.status != 'done';
      final newStatus = isNowDone ? 'done' : 'todo';
      final completedTime = isNowDone ? now : null;

      final batch = _firestore.batch();
      batch.update(_tasksRef.doc(task.id), {
        'status': newStatus,
        'completedAt': completedTime != null
            ? Timestamp.fromDate(completedTime)
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If completing a recurring task, create the next recurring instance!
      if (isNowDone && task.repeatRule != null && task.dueAt != null) {
        final nextDueDate = RecurrenceEngine.computeNextDueDate(
          currentDueDate: task.dueAt!,
          rule: task.repeatRule!,
          completionDate: now,
        );

        if (nextDueDate != null) {
          final nextDocRef = _tasksRef.doc();
          final nextTask = task.copyWith(
            status: 'todo',
            dueAt: nextDueDate,
            completedAt: null,
            clearCompletedAt: true,
            updatedAt: now,
          );
          batch.set(nextDocRef, nextTask.toFirestore());
        }
      }

      await batch.commit();
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed to complete task: $e'));
    }
  }

  @override
  Future<Result<void>> deleteTask(String taskId) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      // Also delete any child subtasks
      final subtasks = await _tasksRef
          .where('parentTaskId', isEqualTo: taskId)
          .get();
      final batch = _firestore.batch();
      for (final doc in subtasks.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_tasksRef.doc(taskId));
      await batch.commit();
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed to delete task: $e'));
    }
  }

  @override
  Future<Result<void>> bulkComplete(List<String> taskIds, bool isDone) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      final batch = _firestore.batch();
      for (final id in taskIds) {
        batch.update(_tasksRef.doc(id), {
          'status': isDone ? 'done' : 'todo',
          'completedAt': isDone ? FieldValue.serverTimestamp() : null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed bulk complete: $e'));
    }
  }

  @override
  Future<Result<void>> bulkDelete(List<String> taskIds) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      final batch = _firestore.batch();
      for (final id in taskIds) {
        batch.delete(_tasksRef.doc(id));
      }
      await batch.commit();
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed bulk delete: $e'));
    }
  }

  @override
  Future<Result<void>> bulkMove(List<String> taskIds, String? listId) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      final batch = _firestore.batch();
      for (final id in taskIds) {
        batch.update(_tasksRef.doc(id), {
          'listId': listId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed bulk move: $e'));
    }
  }

  @override
  Future<Result<void>> bulkSetDueDate(
    List<String> taskIds,
    DateTime? dueAt,
  ) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      final batch = _firestore.batch();
      for (final id in taskIds) {
        batch.update(_tasksRef.doc(id), {
          'dueAt': dueAt != null ? Timestamp.fromDate(dueAt) : null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed bulk set due date: $e'));
    }
  }

  @override
  Future<Result<void>> bulkAddLabel(
    List<String> taskIds,
    String labelId,
  ) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      final batch = _firestore.batch();
      for (final id in taskIds) {
        batch.update(_tasksRef.doc(id), {
          'labelIds': FieldValue.arrayUnion([labelId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed bulk add label: $e'));
    }
  }

  @override
  Future<Result<void>> updateTimeSpent(String taskId, int seconds) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      await _tasksRef.doc(taskId).update({
        'timeSpentSec': FieldValue.increment(seconds),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        StorageException('Failed to update time spent: $e'),
      );
    }
  }

  @override
  Future<Result<void>> batchImportTasks(List<TaskModel> tasks) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      for (var i = 0; i < tasks.length; i += AppConstants.kBatchSize) {
        final chunk = tasks.sublist(
          i,
          i + AppConstants.kBatchSize > tasks.length
              ? tasks.length
              : i + AppConstants.kBatchSize,
        );
        final batch = _firestore.batch();
        for (final task in chunk) {
          final doc = task.id.isNotEmpty
              ? _tasksRef.doc(task.id)
              : _tasksRef.doc();
          batch.set(doc, task.toFirestore());
        }
        await batch.commit();
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Batch import tasks failed: $e'));
    }
  }
}
