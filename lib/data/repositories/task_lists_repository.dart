import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:noteon/core/errors/app_exception.dart';
import 'package:noteon/data/models/task_list_model.dart';

abstract class TaskListsRepository {
  Stream<List<TaskListModel>> watchTaskLists({required String uid});
  Future<Result<TaskListModel>> createTaskList(TaskListModel list);
  Future<Result<void>> updateTaskList(TaskListModel list);
  Future<Result<void>> deleteTaskList(String listId);
}

class FirestoreTaskListsRepository implements TaskListsRepository {
  final FirebaseFirestore _firestore;

  FirestoreTaskListsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _listsRef =>
      _firestore.collection('taskLists');

  @override
  Stream<List<TaskListModel>> watchTaskLists({required String uid}) {
    if (Firebase.apps.isEmpty) return Stream.value([]);
    return _listsRef
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => TaskListModel.fromFirestore(d)).toList()
                ..sort((a, b) => a.order.compareTo(b.order)),
        );
  }

  @override
  Future<Result<TaskListModel>> createTaskList(TaskListModel list) async {
    if (Firebase.apps.isEmpty) return Result.success(list);
    try {
      final docRef = list.id.isNotEmpty
          ? _listsRef.doc(list.id)
          : _listsRef.doc();
      final newList = list.copyWith();
      await docRef.set(newList.toFirestore());
      return Result.success(newList);
    } catch (e) {
      return Result.failure(StorageException('Failed to create task list: $e'));
    }
  }

  @override
  Future<Result<void>> updateTaskList(TaskListModel list) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      await _listsRef.doc(list.id).update(list.toFirestore());
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed to update task list: $e'));
    }
  }

  @override
  Future<Result<void>> deleteTaskList(String listId) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      await _listsRef.doc(listId).delete();
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed to delete task list: $e'));
    }
  }
}
