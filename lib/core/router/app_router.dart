import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteon/data/providers/repository_providers.dart';
import 'package:noteon/features/auth/auth_screen.dart';
import 'package:noteon/features/auth/firebase_setup_screen.dart';
import 'package:noteon/features/auth/onboarding_screen.dart';
import 'package:noteon/features/calendar/calendar_screen.dart';
import 'package:noteon/features/folders/folders_screen.dart';
import 'package:noteon/features/home/main_shell_screen.dart';
import 'package:noteon/features/labels/labels_screen.dart';
import 'package:noteon/features/notes/archive_screen.dart';
import 'package:noteon/features/notes/note_editor_screen.dart';
import 'package:noteon/features/notes/notes_list_screen.dart';
import 'package:noteon/features/notes/trash_screen.dart';
import 'package:noteon/features/search/search_screen.dart';
import 'package:noteon/features/settings/app_lock_screen.dart';
import 'package:noteon/features/settings/app_lock_service.dart';
import 'package:noteon/features/settings/settings_screen.dart';
import 'package:noteon/features/sharing/shared_with_me_screen.dart';
import 'package:noteon/features/stats/stats_screen.dart';
import 'package:noteon/features/tasks/task_detail_screen.dart';
import 'package:noteon/features/tasks/tasks_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final appLockState = ref.watch(appLockProvider);
  final authUser =
      ref.watch(authStateProvider).valueOrNull ??
      ref.read(authRepositoryProvider).currentUser;

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/notes',
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Check App Lock
      if (appLockState.isAppLockEnabled && !appLockState.isUnlocked) {
        if (loc != '/lock') return '/lock';
        return null;
      }
      if (loc == '/lock' && appLockState.isUnlocked) {
        return '/notes';
      }

      // Check Auth
      final isAuthRoute =
          loc == '/auth' || loc == '/onboarding' || loc == '/firebase-setup';
      if (authUser == null && !isAuthRoute) {
        return '/auth';
      }
      if (authUser != null && loc == '/auth') {
        return '/notes';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/lock',
        builder: (context, state) => const AppLockScreen(),
      ),
      GoRoute(
        path: '/firebase-setup',
        builder: (context, state) => FirebaseSetupScreen(
          errorMessage: state.uri.queryParameters['error'],
        ),
      ),

      // Stateful nested navigation for Home Bottom Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Notes
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notes',
                builder: (context, state) => const NotesListScreen(),
              ),
            ],
          ),
          // Branch 1: Tasks
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                builder: (context, state) => const TasksScreen(),
              ),
            ],
          ),
          // Branch 2: Calendar
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          // Branch 3: Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          // Branch 4: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Full-screen Subroutes
      GoRoute(
        path: '/note/:id',
        builder: (context, state) => NoteEditorScreen(
          noteId: state.pathParameters['id'],
          initialType: state.uri.queryParameters['type'] ?? 'text',
        ),
      ),
      GoRoute(
        path: '/task/:id',
        builder: (context, state) => TaskDetailScreen(
          taskId: state.pathParameters['id'],
          initialListId: state.uri.queryParameters['listId'],
          initialNoteId: state.uri.queryParameters['noteId'],
        ),
      ),
      GoRoute(
        path: '/archive',
        builder: (context, state) => const ArchiveScreen(),
      ),
      GoRoute(path: '/trash', builder: (context, state) => const TrashScreen()),
      GoRoute(
        path: '/labels',
        builder: (context, state) => const LabelsScreen(),
      ),
      GoRoute(
        path: '/folders',
        builder: (context, state) => const FoldersScreen(),
      ),
      GoRoute(
        path: '/shared-with-me',
        builder: (context, state) => const SharedWithMeScreen(),
      ),
      GoRoute(path: '/stats', builder: (context, state) => const StatsScreen()),
    ],
  );
});
