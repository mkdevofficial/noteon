import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:noteon/core/errors/app_exception.dart';
import 'package:noteon/data/models/folder_model.dart';

abstract class FoldersRepository {
  Stream<List<FolderModel>> watchFolders({required String uid});
  Future<Result<FolderModel>> createFolder(FolderModel folder);
  Future<Result<void>> updateFolder(FolderModel folder);
  Future<Result<void>> deleteFolder(String folderId);
}

class FirestoreFoldersRepository implements FoldersRepository {
  final FirebaseFirestore _firestore;

  FirestoreFoldersRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _foldersRef =>
      _firestore.collection('folders');

  @override
  Stream<List<FolderModel>> watchFolders({required String uid}) {
    if (Firebase.apps.isEmpty) return Stream.value([]);
    return _foldersRef
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => FolderModel.fromFirestore(d)).toList()
                ..sort((a, b) => a.order.compareTo(b.order)),
        );
  }

  @override
  Future<Result<FolderModel>> createFolder(FolderModel folder) async {
    if (Firebase.apps.isEmpty) return Result.success(folder);
    try {
      final docRef = folder.id.isNotEmpty
          ? _foldersRef.doc(folder.id)
          : _foldersRef.doc();
      final newFolder = folder.copyWith();
      await docRef.set(newFolder.toFirestore());
      return Result.success(newFolder);
    } catch (e) {
      return Result.failure(StorageException('Failed to create folder: $e'));
    }
  }

  @override
  Future<Result<void>> updateFolder(FolderModel folder) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      await _foldersRef.doc(folder.id).update(folder.toFirestore());
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed to update folder: $e'));
    }
  }

  @override
  Future<Result<void>> deleteFolder(String folderId) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      await _foldersRef.doc(folderId).delete();
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed to delete folder: $e'));
    }
  }
}
