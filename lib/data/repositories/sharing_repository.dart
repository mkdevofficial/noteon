import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:noteon/core/errors/app_exception.dart';

class CollaboratorInfo {
  final String uid;
  final String role; // 'owner', 'editor', 'viewer'
  final String displayName;
  final String? email;

  const CollaboratorInfo({
    required this.uid,
    required this.role,
    required this.displayName,
    this.email,
  });
}

abstract class SharingRepository {
  Future<Result<CollaboratorInfo>> shareDocumentByEmail({
    required String collection, // 'notes' or 'taskLists'
    required String documentId,
    required String targetEmail,
    required String role, // 'editor' or 'viewer'
  });

  Future<Result<void>> updateCollaboratorRole({
    required String collection,
    required String documentId,
    required String targetUid,
    required String newRole,
  });

  Future<Result<void>> revokeCollaboratorAccess({
    required String collection,
    required String documentId,
    required String targetUid,
  });

  Future<List<CollaboratorInfo>> fetchCollaboratorProfiles({
    required Map<String, String> roles,
  });
}

class FirestoreSharingRepository implements SharingRepository {
  final FirebaseFirestore _firestore;

  FirestoreSharingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static String hashEmail(String email) {
    return sha256.convert(utf8.encode(email.trim().toLowerCase())).toString();
  }

  @override
  Future<Result<CollaboratorInfo>> shareDocumentByEmail({
    required String collection,
    required String documentId,
    required String targetEmail,
    required String role,
  }) async {
    if (Firebase.apps.isEmpty) {
      return Result.failure(
        const StorageException('Firebase is not initialized'),
      );
    }
    try {
      final emailHash = hashEmail(targetEmail);
      final dirDoc = await _firestore
          .collection('userDirectory')
          .doc(emailHash)
          .get();

      if (!dirDoc.exists || dirDoc.data() == null) {
        return Result.failure(
          const StorageException(
            'No registered NoteOn user found with this email.',
          ),
        );
      }

      final targetUid = dirDoc.data()!['uid'] as String?;
      if (targetUid == null || targetUid.isEmpty) {
        return Result.failure(const StorageException('Invalid user account.'));
      }

      // Fetch user profile for display name
      final userDoc = await _firestore.collection('users').doc(targetUid).get();
      final displayName = userDoc.exists && userDoc.data() != null
          ? (userDoc.data()!['displayName'] as String? ?? 'User')
          : 'User';

      final docRef = _firestore.collection(collection).doc(documentId);
      await docRef.update({
        'memberIds': FieldValue.arrayUnion([targetUid]),
        'roles.$targetUid': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return Result.success(
        CollaboratorInfo(
          uid: targetUid,
          role: role,
          displayName: displayName,
          email: targetEmail.trim(),
        ),
      );
    } catch (e) {
      return Result.failure(StorageException('Failed to share: $e'));
    }
  }

  @override
  Future<Result<void>> updateCollaboratorRole({
    required String collection,
    required String documentId,
    required String targetUid,
    required String newRole,
  }) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      await _firestore.collection(collection).doc(documentId).update({
        'roles.$targetUid': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed to update role: $e'));
    }
  }

  @override
  Future<Result<void>> revokeCollaboratorAccess({
    required String collection,
    required String documentId,
    required String targetUid,
  }) async {
    if (Firebase.apps.isEmpty) return Result.success(null);
    try {
      await _firestore.collection(collection).doc(documentId).update({
        'memberIds': FieldValue.arrayRemove([targetUid]),
        'roles.$targetUid': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure(StorageException('Failed to revoke access: $e'));
    }
  }

  @override
  Future<List<CollaboratorInfo>> fetchCollaboratorProfiles({
    required Map<String, String> roles,
  }) async {
    if (Firebase.apps.isEmpty || roles.isEmpty) return [];
    final list = <CollaboratorInfo>[];
    for (final entry in roles.entries) {
      final uid = entry.key;
      final role = entry.value;
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        final name = doc.exists && doc.data() != null
            ? (doc.data()!['displayName'] as String? ?? 'User')
            : 'User';
        final email = doc.exists && doc.data() != null
            ? (doc.data()!['email'] as String?)
            : null;
        list.add(
          CollaboratorInfo(
            uid: uid,
            role: role,
            displayName: name,
            email: email,
          ),
        );
      } catch (_) {
        list.add(CollaboratorInfo(uid: uid, role: role, displayName: 'User'));
      }
    }
    return list;
  }
}
