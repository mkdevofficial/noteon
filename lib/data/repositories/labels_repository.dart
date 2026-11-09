import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:noteon/core/errors/app_exception.dart';
import 'package:noteon/data/models/label_model.dart';

abstract class LabelsRepository {
  Stream<List<LabelModel>> watchLabels({required String uid});
  Future<Result<LabelModel>> createLabel(LabelModel label);
  Future<Result<void>> updateLabel(LabelModel label);
  Future<Result<void>> deleteLabel(String labelId);
}

class FirestoreLabelsRepository implements LabelsRepository {
  final FirebaseFirestore _firestore;

  FirestoreLabelsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _labelsRef =>
      _firestore.collection('labels');

  @override
  Stream<List<LabelModel>> watchLabels({required String uid}) {
    if (Firebase.apps.isEmpty) return Stream.value([]);
    return _labelsRef
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => LabelModel.fromFirestore(d)).toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            ),
        );
  }

  @override
  Future<Result<LabelModel>> createLabel(LabelModel label) async {
    if (Firebase.apps.isEmpty) return Result.success(label);
    try {
      final docRef = label.id.isNotEmpty
          ? _labelsRef.doc(label.id)
          : _labelsRef.doc();
      final newLabel = label.copyWith();
      await docRef.set(newLabel.toFirestore());
      return Result.success(newLabel);
    } catch (e) {
      return Result.failure(StorageException('Failed to create label: $e'));
    }
  }

  @override
  Future<Result<void>> updateLabel(LabelModel label) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      await _labelsRef.doc(label.id).update(label.toFirestore());
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed to update label: $e'));
    }
  }

  @override
  Future<Result<void>> deleteLabel(String labelId) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      await _labelsRef.doc(labelId).delete();
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed to delete label: $e'));
    }
  }
}
