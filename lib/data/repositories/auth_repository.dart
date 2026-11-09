import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:noteon/core/errors/app_exception.dart';
import 'package:noteon/data/models/user_model.dart';

abstract class AuthRepository {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;

  Future<Result<UserModel>> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<Result<UserModel>> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  });

  Future<Result<UserModel>> signInWithGoogle();

  Future<Result<UserModel>> signInAnonymously();

  Future<Result<UserModel>> upgradeAnonymousWithEmail({
    required String email,
    required String password,
  });

  Future<Result<UserModel>> upgradeAnonymousWithGoogle();

  Future<Result<void>> sendPasswordResetEmail(String email);

  Future<Result<void>> updateDisplayName(String displayName);

  Future<Result<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<Result<void>> signOut();

  Future<Result<void>> deleteAccount(String passwordOrConfirm);
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  static String hashEmail(String email) {
    final clean = email.trim().toLowerCase();
    return sha256.convert(utf8.encode(clean)).toString();
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return _getUserModelFromFirebase(firebaseUser);
    });
  }

  @override
  UserModel? get currentUser {
    final u = _auth.currentUser;
    if (u == null) return null;
    return UserModel(
      uid: u.uid,
      email: u.email ?? '',
      displayName: u.displayName ?? (u.isAnonymous ? 'Guest' : 'User'),
      photoUrl: u.photoURL,
      isAnonymous: u.isAnonymous,
      createdAt: u.metadata.creationTime ?? DateTime.now(),
    );
  }

  Future<UserModel> _getUserModelFromFirebase(User firebaseUser) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (_) {
      // If offline or first time, fallback to Auth user metadata
    }
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName:
          firebaseUser.displayName ??
          (firebaseUser.isAnonymous ? 'Guest' : 'User'),
      photoUrl: firebaseUser.photoURL,
      isAnonymous: firebaseUser.isAnonymous,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  Future<void> _syncUserDocument(User user, {String? displayName}) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final finalDisplayName =
        displayName ??
        user.displayName ??
        (user.isAnonymous ? 'Guest' : 'User');
    final email = user.email ?? '';

    await userRef.set({
      'uid': user.uid,
      'email': email,
      'displayName': finalDisplayName,
      'photoUrl': user.photoURL,
      'isAnonymous': user.isAnonymous,
      'createdAt': Timestamp.fromDate(
        user.metadata.creationTime ?? DateTime.now(),
      ),
    }, SetOptions(merge: true));

    // Register email hash in userDirectory for email sharing lookup
    if (email.isNotEmpty && !user.isAnonymous) {
      final emailHash = hashEmail(email);
      await _firestore.collection('userDirectory').doc(emailHash).set({
        'uid': user.uid,
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<Result<UserModel>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (cred.user != null) {
        await _syncUserDocument(cred.user!);
        final userModel = await _getUserModelFromFirebase(cred.user!);
        return Result.success(userModel);
      }
      return Result.failure(
        const AuthException('Sign in failed: no user returned'),
      );
    } on FirebaseAuthException catch (e) {
      return Result.failure(
        AuthException(_mapFirebaseAuthError(e.code), code: e.code),
      );
    } catch (e) {
      return Result.failure(AuthException(e.toString()));
    }
  }

  @override
  Future<Result<UserModel>> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (cred.user != null) {
        await cred.user!.updateDisplayName(displayName);
        await cred.user!.sendEmailVerification().catchError((_) {});
        await _syncUserDocument(cred.user!, displayName: displayName);
        final userModel = await _getUserModelFromFirebase(cred.user!);
        return Result.success(userModel);
      }
      return Result.failure(const AuthException('Registration failed'));
    } on FirebaseAuthException catch (e) {
      return Result.failure(
        AuthException(_mapFirebaseAuthError(e.code), code: e.code),
      );
    } catch (e) {
      return Result.failure(AuthException(e.toString()));
    }
  }

  @override
  Future<Result<UserModel>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return Result.failure(
          const AuthException('Google Sign-In canceled by user'),
        );
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      if (cred.user != null) {
        await _syncUserDocument(cred.user!);
        final userModel = await _getUserModelFromFirebase(cred.user!);
        return Result.success(userModel);
      }
      return Result.failure(const AuthException('Google Sign-In failed'));
    } on FirebaseAuthException catch (e) {
      return Result.failure(
        AuthException(_mapFirebaseAuthError(e.code), code: e.code),
      );
    } catch (e) {
      return Result.failure(AuthException(e.toString()));
    }
  }

  @override
  Future<Result<UserModel>> signInAnonymously() async {
    try {
      final cred = await _auth.signInAnonymously();
      if (cred.user != null) {
        await _syncUserDocument(cred.user!);
        final userModel = await _getUserModelFromFirebase(cred.user!);
        return Result.success(userModel);
      }
      return Result.failure(const AuthException('Anonymous sign in failed'));
    } on FirebaseAuthException catch (e) {
      return Result.failure(
        AuthException(_mapFirebaseAuthError(e.code), code: e.code),
      );
    } catch (e) {
      return Result.failure(AuthException(e.toString()));
    }
  }

  @override
  Future<Result<UserModel>> upgradeAnonymousWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Result.failure(
          const AuthException('No current user to upgrade'),
        );
      }
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      final userCredential = await user.linkWithCredential(credential);
      if (userCredential.user != null) {
        await _syncUserDocument(userCredential.user!);
        final model = await _getUserModelFromFirebase(userCredential.user!);
        return Result.success(model);
      }
      return Result.failure(const AuthException('Linking account failed'));
    } on FirebaseAuthException catch (e) {
      return Result.failure(
        AuthException(_mapFirebaseAuthError(e.code), code: e.code),
      );
    } catch (e) {
      return Result.failure(AuthException(e.toString()));
    }
  }

  @override
  Future<Result<UserModel>> upgradeAnonymousWithGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Result.failure(
          const AuthException('No current user to upgrade'),
        );
      }
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return Result.failure(const AuthException('Google Sign-In canceled'));
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await user.linkWithCredential(credential);
      if (userCredential.user != null) {
        await _syncUserDocument(userCredential.user!);
        final model = await _getUserModelFromFirebase(userCredential.user!);
        return Result.success(model);
      }
      return Result.failure(const AuthException('Google linking failed'));
    } on FirebaseAuthException catch (e) {
      return Result.failure(
        AuthException(_mapFirebaseAuthError(e.code), code: e.code),
      );
    } catch (e) {
      return Result.failure(AuthException(e.toString()));
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      return Result.failure(
        AuthException(_mapFirebaseAuthError(e.code), code: e.code),
      );
    } catch (e) {
      return Result.failure(AuthException(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateDisplayName(String displayName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Result.failure(const AuthException('User not authenticated'));
      }
      await user.updateDisplayName(displayName);
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure(AuthException(e.toString()));
    }
  }

  @override
  Future<Result<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return Result.failure(const AuthException('User not authenticated'));
      }
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      return Result.failure(
        AuthException(_mapFirebaseAuthError(e.code), code: e.code),
      );
    } catch (e) {
      return Result.failure(AuthException(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteAccount(String passwordOrConfirm) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Result.failure(const AuthException('User not authenticated'));
      }

      // Re-authenticate if email user
      if (!user.isAnonymous &&
          user.email != null &&
          passwordOrConfirm.isNotEmpty) {
        try {
          final cred = EmailAuthProvider.credential(
            email: user.email!,
            password: passwordOrConfirm,
          );
          await user.reauthenticateWithCredential(cred);
        } catch (_) {
          // Reauthentication attempt
        }
      }

      final uid = user.uid;
      final email = user.email;

      // Clean up Firestore data (batch delete notes, tasks, lists, labels, folders)
      final batch = _firestore.batch();

      // 1. Delete userDirectory entry if exists
      if (email != null && email.isNotEmpty) {
        final emailHash = hashEmail(email);
        batch.delete(_firestore.collection('userDirectory').doc(emailHash));
      }

      // 2. Delete user profile doc
      batch.delete(_firestore.collection('users').doc(uid));
      await batch.commit();

      // 3. Delete owned notes
      final notesSnap = await _firestore
          .collection('notes')
          .where('ownerId', isEqualTo: uid)
          .limit(400)
          .get();
      final notesBatch = _firestore.batch();
      for (final doc in notesSnap.docs) {
        notesBatch.delete(doc.reference);
      }
      await notesBatch.commit();

      // 4. Delete owned tasks
      final tasksSnap = await _firestore
          .collection('tasks')
          .where('ownerId', isEqualTo: uid)
          .limit(400)
          .get();
      final tasksBatch = _firestore.batch();
      for (final doc in tasksSnap.docs) {
        tasksBatch.delete(doc.reference);
      }
      await tasksBatch.commit();

      // 5. Delete owned task lists
      final listsSnap = await _firestore
          .collection('taskLists')
          .where('ownerId', isEqualTo: uid)
          .limit(400)
          .get();
      final listsBatch = _firestore.batch();
      for (final doc in listsSnap.docs) {
        listsBatch.delete(doc.reference);
      }
      await listsBatch.commit();

      // 6. Delete owned labels & folders
      final labelsSnap = await _firestore
          .collection('labels')
          .where('ownerId', isEqualTo: uid)
          .limit(400)
          .get();
      final labelsBatch = _firestore.batch();
      for (final doc in labelsSnap.docs) {
        labelsBatch.delete(doc.reference);
      }
      await labelsBatch.commit();

      final foldersSnap = await _firestore
          .collection('folders')
          .where('ownerId', isEqualTo: uid)
          .limit(400)
          .get();
      final foldersBatch = _firestore.batch();
      for (final doc in foldersSnap.docs) {
        foldersBatch.delete(doc.reference);
      }
      await foldersBatch.commit();

      // Finally, delete the Auth user
      await user.delete();
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      return Result.failure(
        AuthException(_mapFirebaseAuthError(e.code), code: e.code),
      );
    } catch (e) {
      return Result.failure(AuthException(e.toString()));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _googleSignIn.signOut().catchError((_) => null);
      await _auth.signOut();
      return Result.success(null);
    } catch (e) {
      return Result.failure(AuthException(e.toString()));
    }
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak (minimum 6 characters).';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      case 'credential-already-in-use':
        return 'This account is already linked to another user.';
      default:
        return 'Authentication error: $code';
    }
  }
}
