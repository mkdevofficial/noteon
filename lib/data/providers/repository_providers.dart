import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteon/data/models/user_model.dart';
import 'package:noteon/data/repositories/auth_repository.dart';
import 'package:noteon/data/repositories/folders_repository.dart';
import 'package:noteon/data/repositories/labels_repository.dart';
import 'package:noteon/data/repositories/local_in_memory_repository.dart';
import 'package:noteon/data/repositories/notes_repository.dart';
import 'package:noteon/data/repositories/sharing_repository.dart';
import 'package:noteon/data/repositories/task_lists_repository.dart';
import 'package:noteon/data/repositories/tasks_repository.dart';

final isFirebaseAvailableProvider = Provider<bool>((ref) {
  return Firebase.apps.isNotEmpty;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final hasFirebase = ref.watch(isFirebaseAvailableProvider);
  if (hasFirebase) {
    return FirebaseAuthRepository();
  }
  return LocalDemoRepository.instance;
});

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final hasFirebase = ref.watch(isFirebaseAvailableProvider);
  if (hasFirebase) {
    return FirestoreNotesRepository();
  }
  return LocalDemoRepository.instance;
});

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  final hasFirebase = ref.watch(isFirebaseAvailableProvider);
  if (hasFirebase) {
    return FirestoreTasksRepository();
  }
  return LocalDemoRepository.instance;
});

final taskListsRepositoryProvider = Provider<TaskListsRepository>((ref) {
  final hasFirebase = ref.watch(isFirebaseAvailableProvider);
  if (hasFirebase) {
    return FirestoreTaskListsRepository();
  }
  return LocalDemoRepository.instance;
});

final labelsRepositoryProvider = Provider<LabelsRepository>((ref) {
  final hasFirebase = ref.watch(isFirebaseAvailableProvider);
  if (hasFirebase) {
    return FirestoreLabelsRepository();
  }
  return LocalDemoRepository.instance;
});

final foldersRepositoryProvider = Provider<FoldersRepository>((ref) {
  final hasFirebase = ref.watch(isFirebaseAvailableProvider);
  if (hasFirebase) {
    return FirestoreFoldersRepository();
  }
  return LocalDemoRepository.instance;
});

final sharingRepositoryProvider = Provider<SharingRepository>((ref) {
  final hasFirebase = ref.watch(isFirebaseAvailableProvider);
  if (hasFirebase) {
    return FirestoreSharingRepository();
  }
  return LocalDemoRepository.instance;
});

// Current User State Stream Provider
final authStateProvider = StreamProvider<UserModel?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

// Sync Status
enum SyncStatus { synced, syncing, offline, error }

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  SyncStatusNotifier() : super(SyncStatus.synced);

  void setStatus(SyncStatus status) {
    state = status;
  }
}

final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
      return SyncStatusNotifier();
    });
